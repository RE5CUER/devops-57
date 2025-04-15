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

