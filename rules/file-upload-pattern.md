# File Upload Pattern for Entity Attachments (CRITICAL)

## Rule
When an entity needs file/image attachments, use the framework's `FileStore` service and `Layer8FileUpload` UI component. Do NOT store binary data in entity fields, build custom upload endpoints, or use external CDN integrations. Entities store only `storage_path` string fields pointing to files managed by FileStore.

## Architecture

```
User → Layer8FileUpload.upload(file) → POST /0/FileStore
                                         ↓
                                    Validates (5MB max)
                                    SHA-256 checksum
                                    Encrypts at rest
                                    Writes to /data/l8files/{docId}/{version}/{fileName}
                                         ↓
                                    Returns { storagePath, fileName, fileSize, mimeType, checksum }
                                         ↓
Form stores storagePath in hidden input → Entity POST/PUT includes storagePath as string field
```

## Proto Pattern

### Single File Per Entity
```protobuf
message MyEntity {
    string entity_id = 1;
    string name = 2;
    // ... other fields ...
    string image_storage_path = 10;       // File path (string, NOT bytes)
    string image_file_name = 11;          // Original filename for display
    int64 image_file_size = 12;           // Size in bytes for display
}
```

### Multiple Files Per Entity (Gallery)
Use embedded children with storage_path fields:
```protobuf
message MyEntity {
    string entity_id = 1;
    string name = 2;
    // ... other fields ...
    repeated MyEntityImage images = 20;   // Multiple files as embedded children
}

message MyEntityImage {
    string image_id = 1;
    string storage_path = 2;             // File path from FileStore
    string file_name = 3;               // Original filename
    int64 file_size = 4;                // Size in bytes
    string caption = 5;                  // User-provided description
    int32 sort_order = 6;               // Display ordering
}
```

## Form Pattern

### Single File Field
```javascript
f.section('Media', [
    ...f.file('imageStoragePath', 'Image'),
])
```

### Multiple Files via Inline Table
```javascript
f.section('Images', [
    ...f.inlineTable('images', 'Images', [
        { key: 'imageId', label: 'ID', hidden: true },
        { key: 'storagePath', label: 'Image', type: 'file' },
        { key: 'caption', label: 'Caption', type: 'text' },
        { key: 'sortOrder', label: 'Order', type: 'number' }
    ]),
])
```

## Upload/Download Flow

### Upload (Add/Edit Form)
1. User drops/selects file in the drop area
2. `Layer8FileUpload.upload(file, documentId, version)` POSTs to `/0/FileStore`
3. FileStore validates size (5MB max), computes SHA-256, encrypts, writes to disk
4. Returns `{ storagePath, fileName, fileSize, mimeType, checksum }`
5. JavaScript stores `storagePath` in hidden form input
6. When user saves the form, entity is created/updated with storagePath string field

### Download (View/Detail Form)
1. Form detects existing storagePath value on the entity
2. Displays filename, size, and Download button
3. User clicks Download → `Layer8FileUpload.download(storagePath, fileName)`
4. FileStore reads file, decrypts, returns base64 data
5. Browser triggers file download with original filename

## FileStore Service Details

| Property | Value |
|----------|-------|
| ServiceName | `FileStore` |
| ServiceArea | `0` (global) |
| Endpoint | `/0/FileStore` |
| Upload | POST with `L8FileUploadRequest` body |
| Download | PUT with `L8FileDownloadRequest` body |
| Storage root | `/data/l8files/` |
| Max file size | 5MB |
| Encryption | AES via `vnic.Resources().Security()` |
| Storage layout | `/{storageRoot}/{documentId}/{version}/{fileName}` |

## What NOT to Do
- Do NOT store binary data (bytes) directly in entity proto fields — use string path references
- Do NOT build custom upload endpoints — use the global FileStore service
- Do NOT skip encryption — FileStore encrypts at rest automatically
- Do NOT use `url` fields pointing to external CDNs — use `storage_path` fields pointing to FileStore
- Do NOT handle file I/O in entity ServiceCallbacks — the entity service just stores the path string

## Backend Integration
No special code is needed in entity services. The FileStore service is activated globally (service area 0). Entity services store the `storagePath` string as-is — no file handling logic in ServiceCallbacks.

## UI Prerequisites
The following l8ui files must be included (already in standard loading order):
- `layer8-file-upload.css` — drop area and status styling
- `layer8-file-upload.js` — upload/download API
- `layer8d-forms-fields-ext.js` — file field rendering and event handlers

## Reference Implementation
`l8physio` — `PhysioExercise` entity with `image_storage_path` and `video_storage_path` fields. Form uses `f.file('imageStoragePath', 'Exercise Image')`.

## PRD Requirement
Every PRD with file/image attachments must specify:
1. Which entities have file fields (single or multiple)
2. Proto field names following the `*_storage_path` convention
3. Form definitions using `f.file()` or inline tables with file columns
