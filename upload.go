package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"time"

	shell "github.com/ipfs/go-ipfs-api"
)

type FileWithCID struct {
	StudentName string `json:"studentName"`
	RollNumber  string `json:"rollNumber"`
	FileName    string `json:"fileName"`
	DateTime    string `json:"dateTime"`
	SHA256      string `json:"sha256"`
	CID         string `json:"cid"`
}

type BlockchainEntry struct {
	BlockName string        `json:"blockName"`
	Files     []FileWithCID `json:"files"`
}

type SelectedFiles struct {
	BlockName string `json:"blockName"`
	Files     []struct {
		FileName    string `json:"fileName"`
		StudentName string `json:"studentName"`
		RollNumber  string `json:"rollNumber"`
		DateTime    string `json:"dateTime"`
	} `json:"files"`
}

func main() {
	sh := shell.NewShell("http://localhost:5001")

	// Ensure the file exists before proceeding
	if _, err := os.Stat("selected_files.json"); os.IsNotExist(err) {
		log.Fatal("Error: selected_files.json does not exist or is empty.")
	}

	// Small delay to ensure the file is completely written before reading
	time.Sleep(2 * time.Second)

	// Read input JSON file
	jsonFile, err := os.Open("selected_files.json")
	if err != nil {
		log.Fatalf("Error opening selected_files.json: %v\n", err)
	}
	defer jsonFile.Close()

	var selected SelectedFiles
	if err := json.NewDecoder(jsonFile).Decode(&selected); err != nil {
		log.Fatalf("Error parsing JSON: %v\n", err)
	}

	// Read blockchain.json
	blockchainFile := "blockchain.json"
	var blockchainData []BlockchainEntry

	if _, err := os.Stat(blockchainFile); err == nil {
		fileContent, err := os.ReadFile(blockchainFile)
		if err != nil {
			log.Fatalf("Error reading blockchain.json: %v\n", err)
		}
		json.Unmarshal(fileContent, &blockchainData)
	}

	// Check if block already exists
	for _, block := range blockchainData {
		if block.BlockName == selected.BlockName {
			fmt.Println("Block already exists. Skipping upload.")
			return
		}
	}

	fmt.Println("Uploading files for new block:", selected.BlockName)

	var newFiles []FileWithCID

	// Upload each file
	for _, fileData := range selected.Files {
		filePath := filepath.Join("files", fileData.FileName)
		f, err := os.Open(filePath)
		if err != nil {
			log.Printf("Skipping file %s: %v\n", filePath, err)
			continue
		}

		// Compute SHA256 hash
		hash := sha256.New()
		if _, err := io.Copy(hash, f); err != nil {
			log.Printf("Error hashing file %s: %v\n", filePath, err)
			f.Close()
			continue
		}
		fileSHA256 := hex.EncodeToString(hash.Sum(nil))

		// Reset file pointer for IPFS upload
		f.Seek(0, 0)

		// Upload to IPFS
		cid, err := sh.Add(f)
		f.Close()
		if err != nil {
			log.Printf("Skipping file %s: Error uploading to IPFS: %v\n", filePath, err)
			continue
		}

		newFiles = append(newFiles, FileWithCID{
			StudentName: fileData.StudentName,
			RollNumber:  fileData.RollNumber,
			FileName:    fileData.FileName,
			DateTime:    fileData.DateTime,
			SHA256:      fileSHA256,
			CID:         cid,
		})
	}

	// Append new block to blockchain.json
	blockchainData = append(blockchainData, BlockchainEntry{
		BlockName: selected.BlockName,
		Files:     newFiles,
	})

	// Write updated blockchain.json
	updatedJSON, err := json.MarshalIndent(blockchainData, "", "  ")
	if err != nil {
		log.Fatalf("Error formatting JSON: %v\n", err)
	}

	err = os.WriteFile(blockchainFile, updatedJSON, 0644)
	if err != nil {
		log.Fatalf("Error writing blockchain.json: %v\n", err)
	}

	fmt.Println("New block added successfully.")
}
