// ./Components/Connect.tsx
import React, { useState } from 'react';
import { connectWallet, disconnectWallet } from '../web3modalConfig';

interface WalletConnectorProps {
  onConnect?: (address: string) => void;
}

const WalletConnector: React.FC<WalletConnectorProps> = ({ onConnect }) => {
  const [account, setAccount] = useState<string | null>(null);
  const [isConnecting, setIsConnecting] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  

  const handleConnect = async () => {
    try {
      setIsConnecting(true);
      setError(null);

      const provider = await connectWallet();
      const signer = provider.getSigner();
      const address = await signer.getAddress();

      setAccount(address);
      if (onConnect) onConnect(address);
    } catch (err: any) {
      console.error("Wallet connection failed:", err);
      setError("Failed to connect wallet. Please try again.");
    } finally {
      setIsConnecting(false);
    }
  };

  const handleDisconnect = async () => {
    await disconnectWallet();
    setAccount(null);
    window.location.reload();
  };

  return (
    <div className="wallet-connector">
      {error && <p className="error-message">{error}</p>}

      {!account ? (
        <button onClick={handleConnect} disabled={isConnecting}>
          {isConnecting ? "Connecting..." : "Connect Wallet"}
        </button>
      ) : (
        <div>
          <p>Connected: {account.slice(0, 6)}...{account.slice(-4)}</p>
          <button onClick={handleDisconnect}>Disconnect</button>
        </div>
      )}
    </div>
  );
};

export default WalletConnector;
