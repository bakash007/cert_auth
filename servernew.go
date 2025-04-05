package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"time"
)

// Helper function to check if `selected_files.json` exists
func fileExists(filename string) bool {
	_, err := os.Stat(filename)
	return err == nil
}

// Helper function to run a Go script
func runScript(scriptName string) error {
	cmd := exec.Command("go", "run", scriptName)
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("Error running %s: %v\nOutput: %s", scriptName, err, output)
		return err
	}
	log.Printf("Successfully ran %s", scriptName)
	return nil
}

// Function to delete `selected_files.json`
func deleteSelectedFiles() {
	if fileExists("selected_files.json") {
		err := os.Remove("selected_files.json")
		if err != nil {
			log.Printf("Error deleting selected_files.json: %v", err)
		} else {
			log.Println("Successfully deleted selected_files.json")
		}
	} else {
		log.Println("selected_files.json does not exist, skipping deletion.")
	}
}

// Handler for block creation
func createBlockHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodOptions {
		// Handle preflight requests for CORS
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != http.MethodPost {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	// **Wait for `selected_files.json` to exist**
	selectedFile := "selected_files.json"
	timeout := 10 * time.Second // Max wait time
	start := time.Now()

	for !fileExists(selectedFile) {
		if time.Since(start) > timeout {
			http.Error(w, `{"error": "selected_files.json not found"}`, http.StatusInternalServerError)
			return
		}
		time.Sleep(500 * time.Millisecond) // Wait 0.5 sec before checking again
	}

	// Step 1: Upload to IPFS
	log.Println("Running upload.go...")
	if err := runScript("upload.go"); err != nil {
		http.Error(w, `{"error": "Failed to upload"}`, http.StatusInternalServerError)
		return
	}
	log.Println("Upload completed.")

	// Step 2: Encryption
	log.Println("Running encrypt.go...")
	if err := runScript("encrypt.go"); err != nil {
		http.Error(w, `{"error": "Failed to encrypt"}`, http.StatusInternalServerError)
		return
	}
	log.Println("Encryption completed.")

	// Step 3: Remove `selected_files.json`
	log.Println("Deleting selected_files.json...")
	deleteSelectedFiles()

	// Response
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"message": "Block created successfully"}`))
}

func main() {
	http.HandleFunc("/create-block", createBlockHandler)
	fmt.Println("Server started on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
