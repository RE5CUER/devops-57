# devops-57
Homework

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

Авторизоваться через браузер (выдаст ссылку — открой её и подтверди).
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

cat /home/grid/.ssh/id_rsa.pub
SHA256
ssh-rsa AAAAB3NzaC1yc2EAAA

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


