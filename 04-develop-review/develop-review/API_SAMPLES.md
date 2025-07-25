# API Testing with cURL

This document contains cURL commands to test the Speaker API endpoints.

## Base URL
The application runs on `http://localhost:8080` by default.

## 1. GET /speakers - Retrieve all speakers

### Basic request (default pagination and sorting)
```bash
curl -X GET "http://localhost:8080/speakers" \
  -H "Accept: application/json"
```

### With custom pagination and sorting
```bash
# Get first page with 10 items, sorted by name
curl -X GET "http://localhost:8080/speakers?pageIndex=0&pageSize=10&sortBy=name" \
  -H "Accept: application/json"

# Get second page with 5 items, sorted by id
curl -X GET "http://localhost:8080/speakers?pageIndex=1&pageSize=5&sortBy=id" \
  -H "Accept: application/json"
```

## 2. POST /speakers - Create a new speaker

### Create a speaker without talks
```bash
curl -X POST "http://localhost:8080/speakers" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "John Doe",
    "organization": "Tech Corp"
  }'
```

### Create a speaker with talks
```bash
curl -X POST "http://localhost:8080/speakers" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Jane Smith",
    "organization": "Innovation Labs",
    "talks": [
      {
        "title": "Introduction to Quarkus",
        "duration": 45
      },
      {
        "title": "Microservices Best Practices",
        "duration": 60
      }
    ]
  }'
```

### Create another speaker for testing
```bash
curl -X POST "http://localhost:8080/speakers" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Bob Johnson",
    "organization": "Startup Inc",
    "talks": [
      {
        "title": "Cloud Native Development",
        "duration": 30
      }
    ]
  }'
```

## 3. DELETE /speakers/{id} - Delete a speaker

### Delete a speaker by ID (replace {id} with actual ID)
```bash
curl -X DELETE "http://localhost:8080/speakers/1" \
  -H "Accept: application/json"
```

## Complete Testing Workflow

### Step 1: Check if there are any existing speakers
```bash
curl -X GET "http://localhost:8080/speakers" \
  -H "Accept: application/json"
```

### Step 2: Create a new speaker
```bash
curl -X POST "http://localhost:8080/speakers" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Alice Brown",
    "organization": "Tech University",
    "talks": [
      {
        "title": "Java Performance Optimization",
        "duration": 50
      }
    ]
  }'
```

### Step 3: Verify the speaker was created
```bash
curl -X GET "http://localhost:8080/speakers" \
  -H "Accept: application/json"
```

### Step 4: Delete the speaker (use the ID from the previous response)
```bash
curl -X DELETE "http://localhost:8080/speakers/1" \
  -H "Accept: application/json"
```

### Step 5: Verify the speaker was deleted
```bash
curl -X GET "http://localhost:8080/speakers" \
  -H "Accept: application/json"
```

## Error Testing

### Try to delete a non-existent speaker
```bash
curl -X DELETE "http://localhost:8080/speakers/999" \
  -H "Accept: application/json"
```

### Try to create a speaker with invalid data
```bash
curl -X POST "http://localhost:8080/speakers" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "",
    "organization": "Test Org"
  }'
```

## Notes

- The API uses JSON for request/response format
- Pagination parameters: `pageIndex` (default: 0), `pageSize` (default: 25)
- Sorting parameters: `sortBy` (default: "id", valid values: "id", "name")
- The POST endpoint returns a 201 status with location header when successful
- The DELETE endpoint returns 404 if the speaker doesn't exist
- All endpoints consume and produce JSON



