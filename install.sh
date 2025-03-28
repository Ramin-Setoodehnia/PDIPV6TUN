#!/bin/bash

# بررسی وضعیت نصب تونل
if grep -q "tunnel-PD" /etc/rc.local 2>/dev/null; then
    STATUS="\e[42m\e[1;37m Installed \e[0m"  # پس‌زمینه سبز برای نصب شده
else
    STATUS="\e[41m\e[1;37m Not Installed \e[0m"  # پس‌زمینه قرمز برای نصب نشده
fi

while true; do
    clear
    echo -e "\e[32m==============================\e[0m"
    echo -e "\e[34m      PDIPV6TUN Installer     \e[0m"
    echo -e "\e[32m==============================\e[0m"
    echo -e " Tunnel Status: $STATUS"
    echo -e "\e[32m==============================\e[0m"
    echo -e "\e[33m1) Install Tunnel\e[0m"
    echo -e "\e[33m2) Show Assigned Local IPv6\e[0m"
    echo -e "\e[33m3) Remove Tunnel\e[0m"
    echo -e "\e[33m4) Exit\e[0m"
    echo -e "\e[32m==============================\e[0m"
    read -p "Select an option: " OPTION

    case $OPTION in
        1)
            echo "Enter remote IPv4 address: "
            read REMOTE_IP
            echo "Enter local IPv4 address: "
            read LOCAL_IP
            echo "Enter local IPv6 address: "
            read LOCAL_IPV6

            # حذف محتوای قبلی /etc/rc.local در صورت وجود
            sudo rm -f /etc/rc.local

            # ایجاد و تنظیم تونل
            sudo ip tunnel add tunnel-PD mode sit remote $REMOTE_IP local $LOCAL_IP ttl 126
            sudo ip link set dev tunnel-PD up mtu 1500
            sudo ip addr add $LOCAL_IPV6/64 dev tunnel-PD
            sudo ip link set tunnel-PD mtu 1436
            sudo ip link set tunnel-PD up

            # ایجاد مجدد /etc/rc.local و اضافه کردن تنظیمات جدید
            cat <<EOF | sudo tee /etc/rc.local
#!/bin/bash

ip tunnel add tunnel-PD mode sit remote $REMOTE_IP local $LOCAL_IP ttl 126
ip link set dev tunnel-PD up mtu 1500
ip addr add $LOCAL_IPV6/64 dev tunnel-PD
ip link set tunnel-PD mtu 1436
ip link set tunnel-PD up

exit 0
EOF

            # دادن مجوز اجرایی به rc.local
            sudo chmod +x /etc/rc.local

            echo -e "\e[32mTunnel setup completed and configured in /etc/rc.local\e[0m"
            read -p "Do you want to reboot the server now? (y/n): " REBOOT_CHOICE
            if [[ "$REBOOT_CHOICE" == "y" ]]; then
                sudo reboot
            fi
            read -p "Press Enter to continue..."
            ;;
        2)
            echo -e "\e[36mAssigned Local IPv6 Address:\e[0m"
            grep -oP 'ip addr add \K[^ ]+' /etc/rc.local 2>/dev/null || echo "No IPv6 assigned."
            read -p "Press Enter to continue..."
            ;;
        3)
            read -p "Are you sure you want to remove the tunnel? (y/n): " CONFIRM_DELETE
            if [[ "$CONFIRM_DELETE" == "y" ]]; then
                echo -e "\e[31mRemoving tunnel...\e[0m"
                sudo ip link set tunnel-PD down
                sudo ip tunnel del tunnel-PD
                sudo rm -f /etc/rc.local
                echo -e "\e[32mTunnel removed successfully.\e[0m"
                read -p "Do you want to reboot the server now? (y/n): " REBOOT_CHOICE
                if [[ "$REBOOT_CHOICE" == "y" ]]; then
                    sudo reboot
                fi
            else
                echo -e "\e[33mTunnel removal canceled.\e[0m"
            fi
            read -p "Press Enter to continue..."
            ;;
        4)
            echo -e "\e[35mExiting...\e[0m"
            exit 0
            ;;
        *)
            echo -e "\e[31mInvalid option!\e[0m"
            read -p "Press Enter to continue..."
            ;;
    esac
done
