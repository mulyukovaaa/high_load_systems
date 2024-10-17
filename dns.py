import socket
import struct
import random


def dns_format_name(domain_name):
    """
    Преобразует доменное имя в формат, используемый в DNS-запросах.

    Args:
        domain_name (str): Доменное имя, которое нужно преобразовать.

    Returns:
        bytes: Доменное имя в формате DNS (длина каждого сегмента + байтовое представление).
    """
    parts = domain_name.split(".")
    formatted_name = b""
    for part in parts:
        formatted_name += struct.pack("B", len(part)) + part.encode("utf-8")
    return formatted_name + b"\x00"


def create_dns_header():
    """
    Создает DNS-заголовок для запроса.

    Returns:
        tuple:
            bytes: Заголовок DNS-запроса в байтовом формате.
            int: ID транзакции для последующей проверки ответа.
    """
    transaction_id = random.randint(0, 65535)  # ID транзакции
    flags = 0x0100  # Флаг, указывающий на стандартный запрос
    questions = 1  # Один вопрос
    answer_rrs = 0  # Пока нет ответа
    authority_rrs = 0
    additional_rrs = 0

    header = struct.pack(
        ">HHHHHH",
        transaction_id,
        flags,
        questions,
        answer_rrs,
        authority_rrs,
        additional_rrs,
    )
    return header, transaction_id


def create_dns_question(domain_name, qtype):
    """
    Создает DNS-вопрос (часть DNS-запроса), указывающий на доменное имя и тип записи.

    Args:
        domain_name (str): Доменное имя, для которого выполняется запрос.
        qtype (int): Тип записи (1 для A-записи, 28 для AAAA-записи).

    Returns:
        bytes: DNS-вопрос в байтовом формате.
    """
    qname = dns_format_name(domain_name)
    qclass = 1
    question = struct.pack(">HH", qtype, qclass)
    return qname + question


def parse_dns_response(data):
    """
    Разбирает DNS-ответ от сервера и выводит результат в зависимости от типа записи (A или AAAA).

    Args:
        data (bytes): Байтовые данные, полученные в ответе от DNS-сервера.
    """
    transaction_id, flags, questions, answer_rrs, authority_rrs, additional_rrs = (
        struct.unpack(">HHHHHH", data[:12])
    )

    offset = 12
    while data[offset] != 0:
        offset += 1
    offset += 5

    print("\n--- Ответ DNS сервера ---")
    print(f"ID транзакции: {transaction_id}")
    print(f"Флаги: {flags:016b}")
    print(f"Число ответов: {answer_rrs}")

    if answer_rrs > 0:
        offset += 2

        answer_type, answer_class, ttl, data_length = struct.unpack(
            ">HHIH", data[offset : offset + 10]
        )
        offset += 10

        if answer_type == 1:
            ip = struct.unpack(">BBBB", data[offset : offset + 4])
            print(f"A-запись: {'.'.join(map(str, ip))}")

        elif answer_type == 28:
            ipv6 = struct.unpack(">8H", data[offset : offset + 16])
            ipv6_address = ":".join(f"{part:x}" for part in ipv6)
            print(f"AAAA-запись: {ipv6_address}")
    else:
        print("Нет ответов.")


def send_dns_query(domain_name, qtype, dns_server):
    """
    Отправляет DNS-запрос к указанному DNS-серверу и обрабатывает ответ.

    Args:
        domain_name (str): Доменное имя для резолвинга.
        qtype (int): Тип запроса (1 для A-записи, 28 для AAAA-записи).
        dns_server (str): IP-адрес DNS-сервера, к которому будет отправлен запрос.
    """
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    server_address = (dns_server, 53)

    dns_header, transaction_id = create_dns_header()
    dns_question = create_dns_question(domain_name, qtype)

    dns_query = dns_header + dns_question

    sock.sendto(dns_query, server_address)

    data, _ = sock.recvfrom(512)  # 512 байт

    received_transaction_id = struct.unpack(">H", data[:2])[0]
    if received_transaction_id == transaction_id:
        print(f"Ответ получен для {domain_name} с типом {qtype}.")
        parse_dns_response(data)
    else:
        print("Ошибка: ID транзакции не совпадает.")

    sock.close()


if __name__ == "__main__":
    domain = "example.com"
    dns_server_main = "8.8.8.8"

    print("Запрос A-записи:")
    send_dns_query(domain, 1, dns_server_main)

    print("\nЗапрос AAAA-записи:")
    send_dns_query(domain, 28, dns_server_main)