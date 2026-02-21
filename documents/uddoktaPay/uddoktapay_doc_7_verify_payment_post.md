Verify Payment

# Verify Payment

# OpenAPI definition

```json
{
  "openapi": "3.1.0",
  "info": {
    "title": "Checkout API",
    "version": "1.0"
  },
  "servers": [
    {
      "url": "https://sandbox.uddoktapay.com/api"
    }
  ],
  "security": [
    {}
  ],
  "paths": {
    "/verify-payment": {
      "post": {
        "summary": "Verify Payment",
        "description": "",
        "operationId": "verify-payment",
        "parameters": [
          {
            "name": "RT-UDDOKTAPAY-API-KEY",
            "in": "header",
            "description": "API KEY",
            "required": true,
            "schema": {
              "type": "string",
              "default": "982d381360a69d419689740d9f2e26ce36fb7a50"
            }
          }
        ],
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "required": [
                  "invoice_id"
                ],
                "properties": {
                  "invoice_id": {
                    "type": "string",
                    "description": "Invoice ID"
                  }
                }
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "200",
            "content": {
              "application/json": {
                "examples": {
                  "Result": {
                    "value": "{}"
                  }
                },
                "schema": {
                  "type": "object",
                  "properties": {}
                }
              }
            }
          },
          "400": {
            "description": "400",
            "content": {
              "application/json": {
                "examples": {
                  "Result": {
                    "value": "{}"
                  }
                },
                "schema": {
                  "type": "object",
                  "properties": {}
                }
              }
            }
          }
        },
        "deprecated": false
      }
    }
  },
  "x-readme": {
    "headers": [],
    "explorer-enabled": true,
    "proxy-enabled": true
  },
  "x-readme-fauxas": true,
  "_id": "630a25adf173c7003d83d096:630a42395e42680047c567f8"
}
```