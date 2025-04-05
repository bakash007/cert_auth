package main

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
)

// AES encryption key (must be 16, 24, or 32 bytes long)
var secretKey = []byte("myverystrongsecretkey123")

// FileInfo struct to store file details
type FileInfo struct {
	StudentName string `json:"studentName"`
	RollNo      string `json:"rollNumber"`
	FileName    string `json:"fileName"`
	DateTime    string `json:"dateTime"`
	Hash        string `json:"sha256"`        // Keeping "sha256" as hash
	EncCID      string `json:"encryptedCID"`  // Stores encrypted CID
}

// Block struct to represent blockchain blocks
type Block struct {
	BlockName string     `json:"blockName"`
	Files     []FileInfo `json:"files"`
}

// Reads blockchain_final.json and returns a set of existing block names
func getExistingBlocks(finalFilePath string) map[string]bool {
	existingBlocks := make(map[string]bool)

	// If blockchain_final.json doesn't exist, initialize it with []
	if _, err := os.Stat(finalFilePath); os.IsNotExist(err) {
		err := ioutil.WriteFile(finalFilePath, []byte("[]"), 0644)
		if err != nil {
			log.Fatalf("Error initializing blockchain_final.json: %v\n", err)
		}
		return existingBlocks
	}

	fileContent, err := ioutil.ReadFile(finalFilePath)
	if err != nil {
		log.Fatalf("Error reading blockchain_final.json: %v\n", err)
	}

	// If file is empty, initialize with empty JSON array
	if len(fileContent) == 0 {
		err := ioutil.WriteFile(finalFilePath, []byte("[]"), 0644)
		if err != nil {
			log.Fatalf("Error resetting blockchain_final.json: %v\n", err)
		}
		return existingBlocks
	}

	var blocks []Block
	err = json.Unmarshal(fileContent, &blocks)
	if err != nil {
		log.Fatalf("Error unmarshalling blockchain_final.json: %v\n", err)
	}

	// Store block names in map
	for _, block := range blocks {
		existingBlocks[block.BlockName] = true
	}

	return existingBlocks
}

func main() {
	blockchainPath := "blockchain.json"
	finalBlockchainPath := "blockchain_final.json"

	// Read blockchain.json
	fileContent, err := ioutil.ReadFile(blockchainPath)
	if err != nil {
		log.Fatalf("Error reading blockchain.json: %v\n", err)
	}

	var blocks []Block
	err = json.Unmarshal(fileContent, &blocks)
	if err != nil {
		log.Fatalf("Error unmarshalling blockchain.json: %v\n", err)
	}

	// Get existing blocks from blockchain_final.json
	existingBlocks := getExistingBlocks(finalBlockchainPath)

	updatedBlocks := []Block{}
	updated := false

	// Iterate through blocks and only encrypt if blockName is not in blockchain_final.json
	for _, block := range blocks {
		if _, exists := existingBlocks[block.BlockName]; exists {
			log.Printf("Skipping encryption for block: %s (already in blockchain_final.json)\n", block.BlockName)
			continue
		}

		// Encrypt CIDs for all files in the block
		newFiles := []FileInfo{}
		for _, file := range block.Files {
			if fileEncCID, err := encryptAES(file.FileName); err == nil {
				file.EncCID = fileEncCID // Encrypt CID
			} else {
				log.Printf("Error encrypting CID for file %s: %v\n", file.FileName, err)
				continue
			}
			newFiles = append(newFiles, file)
		}

		block.Files = newFiles
		updatedBlocks = append(updatedBlocks, block)
		updated = true
	}

	// Append new blocks to blockchain_final.json only if encryption was done
	if updated {
		var finalBlocks []Block

		// Read existing blockchain_final.json
		existingContent, err := ioutil.ReadFile(finalBlockchainPath)
		if err == nil && len(existingContent) > 0 {
			json.Unmarshal(existingContent, &finalBlocks)
		}

		// Append new encrypted blocks
		finalBlocks = append(finalBlocks, updatedBlocks...)

		// Write updated blockchain_final.json
		updatedJSON, err := json.MarshalIndent(finalBlocks, "", "  ")
		if err != nil {
			log.Fatalf("Error formatting JSON: %v\n", err)
		}

		err = ioutil.WriteFile(finalBlockchainPath, updatedJSON, 0644)
		if err != nil {
			log.Fatalf("Error writing updated blockchain_final.json: %v\n", err)
		}

		fmt.Println("Encrypted blocks added to blockchain_final.json")
	} else {
		fmt.Println("No new encryption needed. blockchain_final.json remains unchanged.")
	}
}

// AES encryption function to encrypt the CID
func encryptAES(plainText string) (string, error) {
	block, err := aes.NewCipher(secretKey)
	if err != nil {
		return "", fmt.Errorf("failed to create cipher: %v", err)
	}

	plainTextBytes := []byte(plainText)

	// Padding to make it AES block size compliant
	paddingSize := aes.BlockSize - (len(plainTextBytes) % aes.BlockSize)
	paddedText := append(plainTextBytes, make([]byte, paddingSize)...)

	// IV (Initialization Vector) required for CBC mode
	iv := make([]byte, aes.BlockSize)
	if _, err := io.ReadFull(rand.Reader, iv); err != nil {
		return "", fmt.Errorf("failed to generate IV: %v", err)
	}

	blockMode := cipher.NewCBCEncrypter(block, iv)

	encryptedBytes := make([]byte, len(paddedText))
	blockMode.CryptBlocks(encryptedBytes, paddedText)

	// Return IV + encrypted data as hex string
	return fmt.Sprintf("%x%x", iv, encryptedBytes), nil
}
