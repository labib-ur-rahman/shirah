Create Charge

# Create Charge

> 📘 Introduction
>
> The UddoktaPay Create Charge API allows you to initiate a payment. After a successful payment, an `invoice_id` will be sent via GET or POST request to your specified `redirect_url`. To obtain payment data, you'll need to call the *Verify Payment API*.

## Request URL

To create a payment request, use the following API endpoint:

```
{base_URL}/api/checkout-v2
```

Replace {base\_URL} with the location of your UddoktaPay installation, such as <https://pay.your-domain.com>.

## Request Headers

Include the following request header:

RT-UDDOKTAPAY-API-KEY (required): Your API key. For the sandbox environment, use the provided key:

```
982d381360a69d419689740d9f2e26ce36fb7a50
```

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
    "/checkout-v2": {
      "post": {
        "summary": "Create Charge",
        "description": "",
        "operationId": "create-charge",
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
                  "full_name",
                  "email",
                  "amount",
                  "metadata",
                  "redirect_url",
                  "return_type",
                  "cancel_url"
                ],
                "properties": {
                  "full_name": {
                    "type": "string",
                    "description": "User's full name."
                  },
                  "email": {
                    "type": "string",
                    "description": "User's email address."
                  },
                  "amount": {
                    "type": "string",
                    "description": "The payment amount."
                  },
                  "metadata": {
                    "type": "string",
                    "description": "Additional project-specific data in JSON format. For example: { \"order_id\": \"10\", \"product_id\": \"5\"}",
                    "format": "json"
                  },
                  "redirect_url": {
                    "type": "string",
                    "description": "The URL where the user will be redirected after a successful payment. Additionally, an `invoice_id` will be sent via POST data, which you must validate using the Verify Payment API."
                  },
                  "return_type": {
                    "type": "string",
                    "description": "Specifies how the `invoice_id` is returned to the success page. It can be either \"GET\" or \"POST.\""
                  },
                  "cancel_url": {
                    "type": "string",
                    "description": "The URL where the user will be redirected when they click the cancel button during the payment process."
                  },
                  "webhook_url": {
                    "type": "string",
                    "description": "A backend response URL where payment information is sent when an admin initiates a \"SEND WEBHOOK REQUEST\" from the admin panel."
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
  "_id": "630a25adf173c7003d83d096:630a3eabcf82c20027af10fb"
}
```