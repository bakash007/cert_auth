
package main

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"strings"

	shell "github.com/ipfs/go-ipfs-api"
)

type FileInfo struct {
	Name     string `json:"name"`
	RollNo   string `json:"roll_no"`
	FileName string `json:"file_name"`
	Hash     string `json:"hash"`
	CID      string `json:"cid"`
}

func main() {
	// Load the JSON file
	filePath := "file_uploads.json"
	fileContent, err := os.ReadFile(filePath)
	if err != nil {
		log.Fatalf("Error reading JSON file: %v\n", err)
	}

	var fileInfos []FileInfo
	err = json.Unmarshal(fileContent, &fileInfos)
	if err != nil {
		log.Fatalf("Error unmarshalling JSON data: %v\n", err)
	}

	// Connect to the local IPFS daemon
	ipfs := shell.NewShell("localhost:5001")
	if ipfs == nil {
		log.Fatal("Could not connect to IPFS daemon.")
	}

	// Input the name and roll number
	var name, rollNo string
	fmt.Print("Enter the student's name: ")
	fmt.Scanln(&name)
	fmt.Print("Enter the student's roll number: ")
	fmt.Scanln(&rollNo)

	// Find the file associated with the name and roll_no in the JSON
	var selectedFile FileInfo
	found := false
	for _, file := range fileInfos {
		if strings.EqualFold(file.Name, name) && strings.EqualFold(file.RollNo, rollNo) {
			selectedFile = file
			found = true
			break
		}
	}

	if !found {
		log.Fatalf("File with name %s and roll number %s not found in file_uploads.json\n", name, rollNo)
	}

	// Get the CID from the selected file
	cid := selectedFile.CID
	fmt.Printf("Found CID for %s (Roll No: %s): %s\n", selectedFile.Name, selectedFile.RollNo, cid)

	// File to save the downloaded content
	fmt.Print("Enter the filename to save as: ")
	var outputFile string
	fmt.Scanln(&outputFile)

	// Debugging message
	fmt.Println("Attempting to download file with CID:", cid)

	// Download the file from IPFS
	err = downloadFileFromIPFS(ipfs, cid, outputFile)
	if err != nil {
		log.Fatalf("Error downloading file: %v\n", err)
	}

	// Calculate the SHA256 hash of the downloaded file
	fileHash, err := calculateSHA256(outputFile)
	if err != nil {
		log.Fatalf("Error calculating SHA256 hash of the file: %v\n", err)
	}

	// Compare the hash with the one in the JSON file
	if fileHash == selectedFile.Hash {
		fmt.Println("The downloaded file is valid. Hash matches!")
	} else {
		fmt.Printf("Hash mismatch! Expected: %s, Got: %s\n", selectedFile.Hash, fileHash)
	}
}

// Function to download a file from IPFS using CID
func downloadFileFromIPFS(ipfs *shell.Shell, cid, outputFile string) error {
	// Open the output file for writing
	outFile, err := os.Create(outputFile)
	if err != nil {
		return fmt.Errorf("could not create output file %s: %v", outputFile, err)
	}
	defer outFile.Close()

	// Fetch the file content from IPFS
	fmt.Println("Connecting to IPFS to retrieve file:", cid)
	reader, err := ipfs.Cat(cid)
	if err != nil {
		return fmt.Errorf("failed to retrieve file from IPFS: %v", err)
	}
	defer reader.Close()

	// Write the file content to the output file
	_, err = io.Copy(outFile, reader)
	if err != nil {
		return fmt.Errorf("error writing file: %v", err)
	}

	fmt.Println("File downloaded successfully.")
	return nil
}

// Function to calculate the SHA256 hash of a file
func calculateSHA256(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", fmt.Errorf("could not open file %s: %v", filePath, err)
	}
	defer file.Close()

	hash := sha256.New()
	_, err = io.Copy(hash, file)
	if err != nil {
		return "", fmt.Errorf("error reading file %s: %v", filePath, err)
	}

	return fmt.Sprintf("%x", hash.Sum(nil)), nil
}

