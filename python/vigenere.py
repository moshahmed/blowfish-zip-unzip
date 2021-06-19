# moshahmed
# coding=utf-8

import string, random

# printable = string.ascii_letters + string.digits + string.punctuation + ' '
# alphabets = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
# alphabets = string.ascii_lowercase + string.ascii_uppercase + string.digits
alphabets = string.ascii_lowercase + string.ascii_uppercase + string.digits + string.punctuation
alphalen = len(alphabets)

def hexify(s):
    # To escape unprintable chars as hex in a string s.
    return ''.join(c if c in alphabets else r'\x{0:02x}'.format(ord(c)) for c in s)

def generate_key(message, key_word):
    key = []
    key_word_count = 0
    for x in range(0,len(message)):
        # if message[x] == " ":
        #     key.append(" ")
        if not message[x] in alphabets:
            key.append(message[x])
        else:
            i = key_word_count % len(key_word)
            key.append(key_word[i])
            key_word_count += 1
    key = ''.join(str(i) for i in key)
    return key

def encrypt_vigenere(message,key_word):
    key = generate_key(message,key_word)

    encrypted_text = ""

    for i in range(0,len(message)):
        if not message[i] in alphabets:
            encrypted_text += message[i]
        else:
            encryption_value = (alphabets.find(message[i]) + alphabets.find(key[i])) % alphalen
            encrypted_text += alphabets[encryption_value]

    return encrypted_text

def decrypt_vigenere(message,key_word):
    key = generate_key(message,key_word)

    decrypted_text = ""

    for i in range(0,len(message)):
        if not message[i] in alphabets:
            decrypted_text += message[i]
        else:
            decryption_value = (alphabets.find(message[i]) - alphabets.find(key[i])) % alphalen
            decrypted_text += alphabets[decryption_value]

    return decrypted_text

def random_string(chars=10,puncs=1,digits=3):
    str = ''
    # string.ascii_uppercase + string.ascii_lowercase
    str += ''.join(random.choice(string.ascii_letters ) for i in range(chars))
    str += ''.join(random.choice(string.punctuation) for i in range(puncs))
    str += ''.join(random.choice(string.digits) for i in range(digits))
    return str

def vigenere_show(message,key_word):
    key = generate_key(message, key_word)
    encrypted_text = encrypt_vigenere(message,key_word)
    decrypted_text = decrypt_vigenere(encrypted_text,key_word)

    print(f"key_word: {key_word[0:40]} [0..{len(key_word)}]")
    print(f"Key:      {key[0:40]} [0..{len(key)}]")
    print(f"Cipher:   {encrypted_text[0:40]} [0..{len(encrypted_text)}]")
    print(f"Message:  {message[0:40]} [0..{len(message)}]")
    print(f"Decipher: {decrypted_text[0:40]} [0..{len(decrypted_text)}]")

    print('Success' if message == decrypted_text else 'Error' )
    print('Similar: %2.4f' % similar(message[0:2000], encrypted_text[0:2000]))

def similar(a, b):
    # See https://docs.python.org/3/library/difflib.html#difflib.SequenceMatcher
    # arg1 is lambda func of chars to ignore
    from difflib import SequenceMatcher
    return SequenceMatcher(None, a, b).ratio()

def vigenere_demo():
    # message = str(input("Your message: ")).upper()
    # key_word = str(input("Your key_word: ")).upper()
    # vigenere_show(message,key_word)

    message = 'Hello World 0123 \xb2! What is this char:\xb1?' + '+-------+'
    key_word = 'Moshe@12\xb7'
    vigenere_show(message,key_word)

    message= random_string(40000,10,10)
    key_word = random_string(100,4,4)
    vigenere_show(message,key_word)


if __name__ == '__main__':
    vigenere_demo()
