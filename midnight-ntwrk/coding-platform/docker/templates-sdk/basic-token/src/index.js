const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.static('public'));

// API Routes
app.get('/api/contract', (req, res) => {
    try {
        const contractData = fs.readFileSync(path.join(__dirname, '../build/Token.json'), 'utf8');
        res.json(JSON.parse(contractData));
    } catch (error) {
        res.status(404).json({ error: 'Contract not compiled. Run "make compile" first.' });
    }
});

app.post('/api/deploy', async (req, res) => {
    try {
        // Mock deployment
        const txHash = '0x' + Math.random().toString(16).substr(2, 64);
        const contractAddress = '0x' + Math.random().toString(16).substr(2, 40);
        
        res.json({
            success: true,
            transactionHash: txHash,
            contractAddress: contractAddress,
            network: 'midnight-testnet'
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/transfer', async (req, res) => {
    const { to, amount } = req.body;
    
    if (!to || !amount) {
        return res.status(400).json({ error: 'Missing required parameters: to, amount' });
    }
    
    // Mock transfer
    const txHash = '0x' + Math.random().toString(16).substr(2, 64);
    
    res.json({
        success: true,
        transactionHash: txHash,
        from: '0x1234567890123456789012345678901234567890',
        to: to,
        amount: amount
    });
});

app.get('/api/balance/:address', (req, res) => {
    const { address } = req.params;
    
    // Mock balance
    const balance = Math.floor(Math.random() * 10000);
    
    res.json({
        address: address,
        balance: balance,
        symbol: 'MTK',
        decimals: 18
    });
});

// Serve HTML interface
app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Midnight Token DApp</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
                    max-width: 1200px;
                    margin: 0 auto;
                    padding: 20px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                }
                .container {
                    background: white;
                    border-radius: 12px;
                    padding: 30px;
                    box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                }
                h1 {
                    color: #333;
                    margin-bottom: 10px;
                }
                .subtitle {
                    color: #666;
                    margin-bottom: 30px;
                }
                .card {
                    border: 1px solid #e0e0e0;
                    border-radius: 8px;
                    padding: 20px;
                    margin-bottom: 20px;
                }
                .card h2 {
                    margin-top: 0;
                    color: #667eea;
                }
                button {
                    background: #667eea;
                    color: white;
                    border: none;
                    padding: 10px 20px;
                    border-radius: 6px;
                    cursor: pointer;
                    font-size: 14px;
                    transition: background 0.3s;
                }
                button:hover {
                    background: #5a67d8;
                }
                input {
                    padding: 8px;
                    margin: 5px;
                    border: 1px solid #ddd;
                    border-radius: 4px;
                    width: 200px;
                }
                .status {
                    margin-top: 10px;
                    padding: 10px;
                    border-radius: 4px;
                    background: #f0f0f0;
                    font-family: monospace;
                    font-size: 12px;
                }
                .grid {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 20px;
                }
                @media (max-width: 768px) {
                    .grid { grid-template-columns: 1fr; }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🌙 Midnight Token DApp</h1>
                <p class="subtitle">Privacy-preserving token on Midnight Network</p>
                
                <div class="grid">
                    <div class="card">
                        <h2>Deploy Contract</h2>
                        <button onclick="deployContract()">Deploy Token Contract</button>
                        <div id="deployStatus" class="status" style="display:none;"></div>
                    </div>
                    
                    <div class="card">
                        <h2>Check Balance</h2>
                        <input type="text" id="balanceAddress" placeholder="Enter address">
                        <button onclick="checkBalance()">Check Balance</button>
                        <div id="balanceStatus" class="status" style="display:none;"></div>
                    </div>
                    
                    <div class="card">
                        <h2>Transfer Tokens</h2>
                        <input type="text" id="transferTo" placeholder="Recipient address">
                        <input type="number" id="transferAmount" placeholder="Amount">
                        <button onclick="transferTokens()">Transfer</button>
                        <div id="transferStatus" class="status" style="display:none;"></div>
                    </div>
                    
                    <div class="card">
                        <h2>Contract Info</h2>
                        <button onclick="getContractInfo()">Get Contract Info</button>
                        <div id="contractStatus" class="status" style="display:none;"></div>
                    </div>
                </div>
            </div>
            
            <script>
                async function deployContract() {
                    const status = document.getElementById('deployStatus');
                    status.style.display = 'block';
                    status.innerHTML = 'Deploying contract...';
                    
                    try {
                        const response = await fetch('/api/deploy', { method: 'POST' });
                        const data = await response.json();
                        status.innerHTML = 'Contract deployed!<br>' +
                            'Address: ' + data.contractAddress + '<br>' +
                            'Tx Hash: ' + data.transactionHash;
                    } catch (error) {
                        status.innerHTML = 'Error: ' + error.message;
                    }
                }
                
                async function checkBalance() {
                    const address = document.getElementById('balanceAddress').value;
                    const status = document.getElementById('balanceStatus');
                    
                    if (!address) {
                        alert('Please enter an address');
                        return;
                    }
                    
                    status.style.display = 'block';
                    status.innerHTML = 'Checking balance...';
                    
                    try {
                        const response = await fetch('/api/balance/' + address);
                        const data = await response.json();
                        status.innerHTML = 'Balance: ' + data.balance + ' ' + data.symbol;
                    } catch (error) {
                        status.innerHTML = 'Error: ' + error.message;
                    }
                }
                
                async function transferTokens() {
                    const to = document.getElementById('transferTo').value;
                    const amount = document.getElementById('transferAmount').value;
                    const status = document.getElementById('transferStatus');
                    
                    if (!to || !amount) {
                        alert('Please enter recipient and amount');
                        return;
                    }
                    
                    status.style.display = 'block';
                    status.innerHTML = 'Transferring tokens...';
                    
                    try {
                        const response = await fetch('/api/transfer', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ to, amount })
                        });
                        const data = await response.json();
                        status.innerHTML = 'Transfer successful!<br>' +
                            'Tx Hash: ' + data.transactionHash;
                    } catch (error) {
                        status.innerHTML = 'Error: ' + error.message;
                    }
                }
                
                async function getContractInfo() {
                    const status = document.getElementById('contractStatus');
                    status.style.display = 'block';
                    status.innerHTML = 'Loading contract info...';
                    
                    try {
                        const response = await fetch('/api/contract');
                        const data = await response.json();
                        status.innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                    } catch (error) {
                        status.innerHTML = 'Error: ' + error.message;
                    }
                }
            </script>
        </body>
        </html>
    `);
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Midnight Token DApp running on http://localhost:${PORT}`);
});

module.exports = app;