echo "Запуск terraform destroy..."
terraform destroy -auto-approve || { echo "❌ Ошибка destroy"; exit 1; }
echo "Ожидание 10  секунд перед apply..."
sleep 10
echo "Запуск terraform apply..."
terraform apply -auto-approve || { echo "❌ Ошибка apply"; exit 1; }
echo " Инфраструктура пересоздана."
