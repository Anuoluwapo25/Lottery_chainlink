import React, { useState } from 'react';
import './App.css';
import WalletConnector from './Components/Connect';
import FormFee from './Components/LotteryFee';

function App() {
  const [connectedAddress, setConnectedAddress] = useState<string | null>(null);

  // Handle wallet connection
  const handleConnect = (address: string) => {
    console.log("Connected:", address);
    setConnectedAddress(address);
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Web3 App Test</h1>
        <p>Basic rendering test.</p>

        {/* Wallet connect component */}
        <WalletConnector onConnect={handleConnect} />
      </header>
      <main>
        {/* Pass the connected address to the form */}
        <FormFee connectedAddress={connectedAddress} />
      </main>
    </div>
  );
}

export default App;