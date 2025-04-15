# devops-57

## Шаг 1 Подготовка управляющей ноды

Установим тераформ  
Terraform v1.11.3  
Скачиваем архив с официального сайта  
https://developer.hashicorp.com/terraform/install  

Установим через пакет ансибл  
ansible [core 2.16.3]  

Для работы с terraform понадобится создать токен авторизации в yandex.cloud  

Установим Yandex Cloud CLI  
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash  
yc init  

Авторизоваться через браузер по представленной ссылке  
Выбрать каталог (folder) и облако (cloud).  
Установить зону доступности по умолчанию (например, ru-central1-a).  

После авторизации получим данные для провайдера терраформ по команде  

cat ~/.config/yandex-cloud/config.yaml  

Где:

oauth_token: <you_token>  
cloud_id: <you_cloud_id>  
folder_id: <you_folder_id>  
zone: Ваша зона по умолчанию

Для дальнейшей работы с терраформ в РФ установим зеркало  

nano ~/.terraformrc  

provider_installation {
  network_mirror {
    url     = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}

Создадим ssh ключ для работы с ансибл  

ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa  
cat /root/.ssh/id_rsa.pub  


## Шаг 2 Деплой

Скачиваем проект с GitHub https://github.com/RE5CUER/devops-57.git  
Переходим в папку dip/terraform  
запускаем  
 
terraform plan  
terraform apply  

После окончания деплоя будут выведены в консоль внешние ip адреса виртуальных машин, а также эти данные появятся в файле dip/ansible/inventory.nano  

![image](https://github.com/user-attachments/assets/52be9126-614b-4c15-8a48-401cd06f0a21)  

На данном этапе мы развернём 3 виртуальные машины  
k8s-master  
k8s-app  
srv  
![image](https://github.com/user-attachments/assets/8c233d30-ee79-427b-97c4-4e88314703e2)  

# Внимание!
Для присоеденения k8s-app в k8s-master необходимо указать ip k8s-master в файле dip/ansible/k8s.yml в строках  

wait_for: "host=<k8s-master ip> port=6443 timeout=1"  
shell: "{{ hostvars['<k8s-master ip>'].join_command }} >> node_joined.log"  

В случае если понадобится редеплой, воспользуйтесь скриптом  
dip/terraform/redeploy.sh  
chmod +x redeploy.sh  
./redeploy.sh  

Далее переходим в dip/ansible/  
Проверим доступность хостов командой  
ansible all -i inventory.ini -m ping  

![image](https://github.com/user-attachments/assets/4127c234-aa6f-4680-98e9-d8530ee142cd)  

Далее поочерёдно запускаем командой  
ansible-playbook -i inventory.ini <my_yml>.yml  

Следующие плэйбуки  

apt.yml  
Установка необходимых зависимостей, базового ПО  

k8s.yml  
Настройка кластера кубернетис  

ci.yml  
Развёртывание инструментов CI/CD  

monitoring.yml  
Развёртывание инструментов мониторинга  

## Шаг 3 Настройка подключения к кластеру и Docker Registry

Настройка доступа к Kubernetes-кластеру для srv  

Подключаемся к k8s-master  
ssh ubuntu@<k8s-master_ip>  

Вывводим данные для подключения к кластеру  
cat ~/.kube/config  

Содержимое переносим на srv  
Подключаемся к srv  
ssh ubuntu@<srv>  

mkdir -p ~/.kube  
nano ~/.kube/config  

проверим

kubectl get nodes  

В качестве докер регистра я выбрал docker-hub  
Для этого необходимо зарегестрироваться в docker-hub и создать секрет  

создаём секрет для авторизации на docker-hub  

kubectl create secret docker-registry regcred \  
  --docker-server=https://hub.docker.com/ \  
  --docker-username=<you_docker-hub_login> \  
  --docker-password=<you_dockerhub_password> \  
  --docker-email=<you_email>  

## Шаг 4 Настройка GitLab

Конфигурируем gitlab на внешний ip srv  

sudo sed -i "s|^external_url .*|external_url 'http://51.250.81.129'|" /etc/gitlab/gitlab.rb  
sudo gitlab-ctl reconfigure && sudo gitlab-ctl restart && sudo gitlab-ctl status  

При первой настройке пароль от GitLab можно посмотреть вот тут:  
sudo nano /etc/gitlab/initial_root_password  

Авторизуемся под root, при желании меняем пароль на свой  

Клонируем репозиторий с django приложением к себе в гитлаб  

cd /папка для проекта  
git clone https://github.com/vinhlee95/django-pg-docker-tutorial.git  
cd django-pg-docker-tutorial  
Удаляем старую привязку к GitHub (опционально)  
git remote remove origin  
git remote add origin http:/<srv_ip>/путь до проекта/django-pg-docker-tutorial.git  
Вводим лог/пас от пароля GitLab  
git push --all origin  
git push --tags origin  

## Шаг 5 Настраиваем GitLab-runner

Зарегестрируем наш runner в GitLab  

sudo gitlab-runner register  

http://<srv_ip>  
Вводи токен регистрации Ранера   
(Токен можно получить в GitLab Admin area > CI/CD > Runners > три точки в правом углу)  
Даём название нашему ранеру my_run  
Enter  
shell  
shell  

Проверяем конфигурационный файл  

sudo cat /etc/gitlab-runner/config.toml  

Запускаем ранер  
sudo gitlab-runner start  

Назначаем права для работы c GitLab  

usermod -aG docker ubuntu  
usermod -aG docker root  
usermod -aG docker gitlab-runner  

Скопируем конфигурации кластера в gitlab-runner  

sudo cp /root/.kube/config /home/gitlab-runner/.kube/config  
sudo chown gitlab-runner:gitlab-runner /home/gitlab-runner/.kube/config  
sudo chmod 644 /home/gitlab-runner/.kube/config  

Настраиваем переменные в GitLab  

Далее настраиваю переменные в ГИТЛАБ для логина в Docker HUB  
DOCKER_PASSWORD - пароль на докерхаб  
DOCKER_USER - логин в докерхаб  
Settings > CI/CD > Variables  

![image](https://github.com/user-attachments/assets/0ac36564-ddcf-4fce-b01e-c3ea4a147e0c)  


Перезапускаем докер и гитлаб  

sudo systemctl restart docker  
sudo gitlab-runner restart  

Проверяем подключение gitlab-runner  
Admin area > CI/CD > Runner  
![image](https://github.com/user-attachments/assets/9a341d89-b126-4e30-9644-f38b94bc4d22)  

## Шаг 6 запуск Pipline

Перенесите в корень проекта GitLab  
.gitlab-ci.yml  

Из проекта   
https://github.com/RE5CUER/devops-57.git  

Далее переходим к запуску pipeline  
project > Build > Pipeline > Run pipeline  

Проверяем  

Работа pipline в GitLab:  
![image](https://github.com/user-attachments/assets/0c33325a-d072-4825-b254-5b2ad1b87f4b)  
![image](https://github.com/user-attachments/assets/dd093a18-9397-4494-bc7b-9811d88dda72)  

Загрузка образа на docker-hub:  
![image](https://github.com/user-attachments/assets/3e6d2259-c9af-4162-a96c-71e39429b2d7)  

Проверим на srv созданые поды на кластере:  
kubectl get pods  
![image](https://github.com/user-attachments/assets/6d6c6baa-3b90-4db3-9b68-22036b0a97d8)  

Перейдём на адрес приложения:  

k8s-master  
http://89.169.136.108:30100/  
![image](https://github.com/user-attachments/assets/aaeddf2d-9fc3-463a-9b82-fc123cdf0c7f)  

k8s-app  
http://89.169.136.91:30100/  
![image](https://github.com/user-attachments/assets/ea986c66-852f-4963-8881-4fe0e188d8d0)  









  



