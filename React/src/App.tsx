// App.tsx
import React from 'react';
import './App.css';
import WalletConnector from './Components/Connect';
import FormFee from './Components/LotteryFee';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>Web3 App Test</h1>
        <p>Basic rendering test.</p>

        {/* Wallet connect component */}
        <WalletConnector onConnect={(address) => console.log("Connected:", address)} />
      </header>
      <main>
        <FormFee />
      </main>
    </div>
  );
}

export default App;
