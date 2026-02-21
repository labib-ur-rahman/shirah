Create Charge

# Create Charge

This API will receive a payment creation request with necessary information.

## Introduction

The UddoktaPay Create Charge API enables you to receive payment creation requests and initiate payments. This documentation offers comprehensive guidance on utilizing this API effectively.

## Request URL

To create a payment request, use the following API endpoint:

```
{base_URL}/api/checkout-v2
```

Where {base\_URL} is the location of your UddoktaPay installation, such as <https://pay.your-domain.com>.

## Request Headers

Include the following request headers:

| Header Name           | Value                          |
| :-------------------- | :----------------------------- |
| Content-Type          | "application/json"             |
| Accept                | "application/json"             |
| RT-UDDOKTAPAY-API-KEY | Collect API KEY From Dashboard |

## Request Parameters

The API expects the following parameters in the request:

| Property     | Presence  | Type        | Description                                                                                                                                                                                           |
| :----------- | :-------- | :---------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| full\_name    | Mandatory | string      | User's full name                                                                                                                                                                                      |
| email        | Mandatory | string      | User's email                                                                                                                                                                                          |
| amount       | Mandatory | string      | Payment amount                                                                                                                                                                                        |
| metadata     | Mandatory | JSON object | A JSON object for additional project-specific data.                                                                                                                                                   |
| redirect\_url | Mandatory | string      | Base URL of the merchant's platform. UddoktaPay will generate separate callback URLs for success, failure, and canceled transactions based on this URL.                                               |
| return\_type  | Optional  | string      | "POST" (default) or "GET." Specifies the return URL data format. In "POST" format, UddoktaPay sends the invoice\_id with a POST request. In "GET" format, the invoice\_id is sent as a query parameter. |
| cancel\_url   | Mandatory | string      | URL for canceled transaction notifications.                                                                                                                                                           |
| webhook\_url  | Optional  | string      | IPN callback URL for manual data submission from the admin dashboard.                                                                                                                                 |

## Success Response Parameters

[block:parameters]
{
  "data": {
    "h-0": "Property",
    "h-1": "Type",
    "h-2": "Description",
    "0-0": "status",
    "0-1": "bool",
    "0-2": "TRUE",
    "1-0": "message",
    "1-1": "string",
    "1-2": "The message associated with the status, explaining the status.",
    "2-0": "payment_url",
    "2-1": "string",
    "2-2": "The URL of UddoktaPay where the customer should be forwarded to complete his payment.  \n  \nExample:  \n<https://sandbox.uddoktapay.com/payment/64c0d6077f0be49801bdd142a05518193574d31d>"
  },
  "cols": 3,
  "rows": 3,
  "align": [
    "left",
    "left",
    "left"
  ]
}
[/block]

## Error Response Parameters

| Property | Type   | Description                                                  |
| :------- | :----- | :----------------------------------------------------------- |
| status   | bool   | FALSE                                                        |
| message  | string | The message associated with the status, explains the status. |

## Sample Request

```curl
curl --request POST \
     --url https://sandbox.uddoktapay.com/api/checkout-v2 \
     --header 'RT-UDDOKTAPAY-API-KEY: 982d381360a69d419689740d9f2e26ce36fb7a50' \
     --header 'accept: application/json' \
     --header 'content-type: application/json' \
     --data '
{
     "full_name": "John Doe",
     "email": "userEmail@gmail.com",
     "amount": "100",
     "metadata": {
          "user_id": "10",
          "order_id": "50"
     },
     "redirect_url": "https://your-domain.com/success",
     "cancel_url": "https://your-domain.com/cancel",
     "webhook_url": "https://your-domain.com/ipn"
}
'
```
```javascript
const axios = require('axios');

const options = {
  method: 'POST',
  url: 'https://sandbox.uddoktapay.com/api/checkout-v2',
  headers: {
    accept: 'application/json',
    'RT-UDDOKTAPAY-API-KEY': '982d381360a69d419689740d9f2e26ce36fb7a50',
    'content-type': 'application/json'
  },
  data: {
    full_name: 'John Doe',
    email: 'userEmail@gmail.com',
    amount: '100',
    metadata: {user_id: '10', order_id: '50'},
    redirect_url: 'https://your-domain.com/success',
    cancel_url: 'https://your-domain.com/cancel',
    webhook_url: 'https://your-domain.com/ipn'
  }
};

axios
  .request(options)
  .then(function (response) {
    console.log(response.data);
  })
  .catch(function (error) {
    console.error(error);
  });
```

## Sample Response

```json
{
  "status": true,
  "message": "Payment Url",
  "payment_url": "https://sandbox.uddoktapay.com/payment/254663aa2a6a4a5df2aa8dc9f28aa1744a8bae9f"
}
```