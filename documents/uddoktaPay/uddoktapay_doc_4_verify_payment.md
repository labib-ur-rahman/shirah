Verify Payment

# Verify Payment

This API will provide the current status of a specific payment.

## Introduction

The UddoktaPay Verify Payment API allows you to retrieve the current status of a specific payment. After initiating a payment through the Create Charge API, UddoktaPay sends the `invoice_id` as a query parameter to the success URL. You can use this `invoice_id` to call the Verify Payment API at any time to check the payment status.

## Request URL

To create a payment request, use the following API endpoint:

```
{base_URL}/api/verify-payment
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

The API expects the following parameter in the request:

| Property   | Presence  | Type   | Description                                                                                            |
| :--------- | :-------- | :----- | :----------------------------------------------------------------------------------------------------- |
| invoice\_id | Mandatory | string | The invoice\_id is received as a query parameter from the success URL provided during payment creation. |

## Success Response Parameters

Upon a successful API request, the response will contain the following parameters:

[block:parameters]
{
  "data": {
    "h-0": "Property",
    "h-1": "Type",
    "h-2": "Description",
    "0-0": "full_name",
    "0-1": "string",
    "0-2": "Full Name value which was passed along with the payment request.",
    "1-0": "email",
    "1-1": "string",
    "1-2": "Email value which was passed along with the payment request.",
    "2-0": "amount",
    "2-1": "string",
    "2-2": "Amount value which was passed along with the payment request.",
    "3-0": "fee",
    "3-1": "string",
    "3-2": "Fee of the payment transaction.",
    "4-0": "charged_amount",
    "4-1": "string",
    "4-2": "Amount of the payment transaction.",
    "5-0": "invoice_id",
    "5-1": "string",
    "5-2": "UddoktaPay generated invoice_id for this payment creation request.",
    "6-0": "metadata",
    "6-1": "JSON object",
    "6-2": "Any related JSON object that was passed along with the payment request.",
    "7-0": "payment_method",
    "7-1": "string",
    "7-2": "Payment Method of the payment transaction. (bKash/Rocket/Nagad/Upay or Bank)",
    "8-0": "sender_number",
    "8-1": "string",
    "8-2": "Sender Number of the payment transaction.",
    "9-0": "transaction_id",
    "9-1": "string",
    "9-2": "Transaction ID of the payment transaction.",
    "10-0": "date",
    "10-1": "string",
    "10-2": "Date of the payment transaction.",
    "11-0": "status",
    "11-1": "string",
    "11-2": "COMPLETED or PENDING or ERROR  \n  \nStatus of the payment."
  },
  "cols": 3,
  "rows": 12,
  "align": [
    "left",
    "left",
    "left"
  ]
}
[/block]

## Error Response Parameters

In case of an error, the response will contain the following parameters:

| Property | Type   | Description                                                |
| :------- | :----- | :--------------------------------------------------------- |
| status   | string | ERROR                                                      |
| message  | string | Message associated with the status, explaining the status. |

## Sample Request

```curl
curl --request POST \
     --url https://sandbox.uddoktapay.com/api/verify-payment \
     --header 'RT-UDDOKTAPAY-API-KEY: 982d381360a69d419689740d9f2e26ce36fb7a50' \
     --header 'accept: application/json' \
     --header 'content-type: application/json' \
     --data '
{
     "invoice_id": "Erm9wzjM0FBwjSYT0QVb"
}
'
```
```javascript
const axios = require('axios');

const options = {
  method: 'POST',
  url: 'https://sandbox.uddoktapay.com/api/verify-payment',
  headers: {
    accept: 'application/json',
    'RT-UDDOKTAPAY-API-KEY': '982d381360a69d419689740d9f2e26ce36fb7a50',
    'content-type': 'application/json'
  },
  data: {invoice_id: 'Erm9wzjM0FBwjSYT0QVb'}
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
  "full_name": "John Doe",
  "email": "userEmail@gmail.com",
  "amount": "100.00",
  "fee": "0.00",
  "charged_amount": "100.00",
  "invoice_id": "Erm9wzjM0FBwjSYT0QVb",
  "metadata": {
    "user_id": "10",
    "order_id": "50"
  },
  "payment_method": "bkash",
  "sender_number": "01311111111",
  "transaction_id": "TESTTRANS1",
  "date": "2023-01-07 14:00:50",
  "status": "COMPLETED"
}
```