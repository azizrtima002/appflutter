import express from 'express';
import cors from 'cors';

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (_req, res) => {
  res.send('Stripe mock is running. POST /create-payment-intent with {amount_cents,currency}.');
});

app.post('/create-payment-intent', async (req, res) => {
  const { amount_cents, currency, metadata } = req.body || {};
  if (!amount_cents || !currency) {
    return res.status(400).json({ error: 'amount_cents and currency required' });
  }
  // In real server, use Stripe SDK with secret key to create a PaymentIntent
  // Here we return a fake client secret to let PaymentSheet init
  const fake = `pi_mock_${Math.random().toString(36).slice(2)}_secret_${Date.now()}`;
  res.json({ clientSecret: fake, metadata });
});

const port = process.env.PORT || 4242;
app.listen(port, () => console.log(`Mock server running on http://localhost:${port}`));
