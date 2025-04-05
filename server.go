package main

import (
	"fmt"
	"log"
	"net/http"
	"os/exec"
)

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

	// Response
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"message": "Block created successfully"}`))
}

func main() {
	http.HandleFunc("/create-block", createBlockHandler)
	fmt.Println("Server started on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
