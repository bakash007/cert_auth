
package main

import (
	"crypto/aes"
	"crypto/cipher"
	"encoding/hex"
	"errors"
	"fmt"
)

var secretKey = []byte("myverystrongsecretkey123") // Replace with your actual 32-byte secret key

func main() {
	fmt.Print("Enter the encrypted CID: ")
	var encryptedCID string
	fmt.Scanln(&encryptedCID)

	decryptedCID, err := decryptAES(encryptedCID)
	if err != nil {
		fmt.Printf("Error decrypting CID: %v\n", err)
		return
	}

	fmt.Printf("Decrypted CID: %s\n", decryptedCID)
}

func decryptAES(encryptedCID string) (string, error) {
	// Decode the hex string
	encryptedBytes, err := hex.DecodeString(encryptedCID)
	if err != nil {
		return "", fmt.Errorf("failed to decode hex string: %v", err)
	}

	// Ensure the encrypted data length is a multiple of the block size
	if len(encryptedBytes)%aes.BlockSize != 0 {
		return "", errors.New("encrypted data is not a multiple of the block size")
	}

	// Create AES cipher
	block, err := aes.NewCipher(secretKey)
	if err != nil {
		return "", fmt.Errorf("failed to create cipher: %v", err)
	}

	// Decrypt using CBC mode
	blockMode := cipher.NewCBCDecrypter(block, secretKey[:aes.BlockSize])
	decryptedBytes := make([]byte, len(encryptedBytes))
	blockMode.CryptBlocks(decryptedBytes, encryptedBytes)

	// Remove padding (PKCS#7)
	padding := int(decryptedBytes[len(decryptedBytes)-1])
	if padding > len(decryptedBytes) || padding == 0 {
		return "", errors.New("invalid padding size")
	}
	decryptedBytes = decryptedBytes[:len(decryptedBytes)-padding]

	return string(decryptedBytes), nil
}

