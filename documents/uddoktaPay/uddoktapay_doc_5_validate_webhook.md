Validate Webhook

# Validate Webhook

> ❗️ Note
>
> Ensure that you include the webhook URL in the 'webhook\_url' parameter when making a request to the Create Charge API.

## Code Example

```javascript
const express = require('express');
const app = express();
const port = 3000; // You can choose any available port

// Define your API key
const apiKey = '982d381360a69d419689740d9f2e26ce36fb7a50';

// Middleware to parse JSON
app.use(express.json());

// Webhook endpoint
app.post('/webhook', (req, res) => {
  // Get the API key from the request headers
  const headerApi = req.headers['rt-uddoktapay-api-key'];

  // Verify the API key
  if (headerApi !== apiKey) {
    res.status(401).send('Unauthorized Action');
    return;
  }

  // Webhook data
  const webhookData = req.body;

  // Handle the webhook data
  console.log('Webhook Data Received:');
  console.log(webhookData);

  // You can now process the data as needed

  res.status(200).send('Webhook received successfully');
});

app.listen(port, () => {
  console.log(`Webhook server is running on port ${port}`);
});
```

## Sample Payloads

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