# Author            : Ryszard Pytka 198323 (s198323@student.pg.edu.pl)
# Created On        : 30.05.2024
# Last Modified By  : Ryszard Pytka 198323 (s198323@student.pg.edu.pl)
# Last Modified On  : ......
# Version           : 2.0
#
# Description       :
# Poniższy skrypt, pozwala na przesłanie wybranego przez użytkownika pliku do folderu DropBox, po ówczesnym jego zaszyfrowaniu
# algorytmem AES-256-CBC 

#!/bin/bash

show_help() {
    echo "Instrukcja poprawnego uruchomienia skryptu:"
    echo "./duzy_skrypt.sh <ścieżka do pliku> <hasło szyfrujące>"
}

# Funkcja do wyświetlania pomocy
show_options() {
    echo "Opcje:"
    echo "  -h           Wyświetla pomoc"
    echo "  -v           Wyświetla wersję skryptu"
}

# Funkcja do wyświetlania wersji
show_version() {
    echo "Wersja 2.0"
}

# Funkcja do szyfrowania pliku
encrypt_file() {
    local file="$1"
    local password="$2"
    local encrypted_file="${file}.enc"

    openssl enc -aes-256-cbc -salt -in "$file" -out "$encrypted_file" -k "$password"
    echo "$encrypted_file"
}

# Funkcja do przesyłania pliku do Dropbox
upload_to_dropbox() {
    local file="$1"
    local token="$2"

 local response=$(curl -s -X POST https://content.dropboxapi.com/2/files/upload \
        --header "Authorization: Bearer $token" \
        --header "Dropbox-API-Arg: {\"autorename\":false,\"mode\":\"add\",\"mute\":false,\"path\":\"/$(basename "$file")\",\"strict_conflict\":false}" \
        --header "Content-Type: application/octet-stream" \
        --data-binary @"$file")

    if [[ $(echo "$response" | grep -c "\"error_summary\":") -eq 0 ]]; then
        echo "Plik został przesłany do Dropbox."
        echo "Odpowiedź Dropbox: $response"
    else
        echo "Wystąpił błąd podczas przesyłania pliku."
        echo "Odpowiedź Dropbox: $response"
    fi
}

# Główna funkcja skryptu
main() {
    local access_token="sl.B2YYOX0eIgULnj6J8Z-ya8jvPKE5iv-XzGmrz_2VkVCy5LB0d3SnjzR0G2xKqhKduhFyFtcH1L1oP1EliqXAhu8BLlYmGfXNFaYMhALwqZHud1kLDxnFhGOKwook9KUbGAGaaU4LUtCJ"  # Pobierz Access Token z zmiennej środowiskowej
    local file="$1"
    local password="$2"

    if [[ -z "$access_token" ]]; then
        echo "Błąd: Zmienna środowiskowa DROPBOX_ACCESS_TOKEN nie jest ustawiona."
        exit 1
    fi

    echo "Sprawdzanie pliku: $file"
    if [[ ! -f "$file" ]]; then
        echo "Błąd: Plik $file nie istnieje."
        exit 1
    fi

    echo "Szyfrowanie pliku..."
    local encrypted_file=$(encrypt_file "$file" "$password")

    echo "Przesyłanie zaszyfrowanego pliku do Dropbox..."
    upload_to_dropbox "$encrypted_file" "$access_token" "$folder"

    echo "Operacja zakończona."
}

# Sprawdzenie, czy podano odpowiednią liczbę argumentów i obsługa opcji
if [[ "$#" -lt 1 ]]; then
    echo "Błąd: Nie podano żadnych argumentów."
    show_options
    exit 1
fi

while getopts "hv" opt; do
    case ${opt} in
        h )
            show_help
            exit 0
            ;;
        v )
            show_version
            exit 0
            ;;
        \? )
            show_options
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# Sprawdzenie, czy podano odpowiednią liczbę argumentów po przetworzeniu opcji
if [[ "$#" -ne 2 ]]; then
    echo "Błąd: Nie podano odpowiedniej liczby argumentów."
    show_help
    exit 1
fi

# Uruchomienie głównej funkcji skryptu z podanymi argumentami
main "$1" "$2"