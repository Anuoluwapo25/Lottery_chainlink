import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';

import LotteryVRFAbi from '../utils/abi.json';


interface FormFeeProps {
  connectedAddress?: string | null;
}

const FormFee: React.FC<FormFeeProps> = ({ connectedAddress }) => {
  const contractAddress = "";

  
  const [feeAmount, setFeeAmount] = useState<string>('0.001');
  const [minFee, setMinFee] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [playerCount, setPlayerCount] = useState<number>(0);

  useEffect(() => {
    const fetchContractData = async () => {
      if (!contractAddress || !window.ethereum) return;
      
      try {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const lotteryContract = new ethers.Contract(
          contractAddress,
          LotteryVRFAbi.abi,
          provider
        );
        
     
        const entranceFee = await lotteryContract.getEntranceFee();
        setMinFee(ethers.utils.formatEther(entranceFee));
        
        const numPlayers = await lotteryContract.getNumberOfPlayers();
        setPlayerCount(numPlayers.toNumber());
      } catch (err) {
        console.error("Failed to fetch contract data:", err);
      }
    };
    
    if (connectedAddress) {
      fetchContractData();
    }
  }, [contractAddress, connectedAddress]);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    
    if (!connectedAddress) {
      setErrorMsg("Please connect your wallet first");
      return;
    }
    
    if (!feeAmount || parseFloat(feeAmount) <= 0) {
      setErrorMsg("Please enter a valid fee amount");
      return;
    }
    
    setIsSubmitting(true);
    setErrorMsg(null);
    setSuccessMsg(null);
    
    try {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const lotteryContract = new ethers.Contract(
        contractAddress,
        LotteryVRFAbi.abi,
        signer
      );
      
      const feeInWei = ethers.utils.parseEther(feeAmount);
      
      const tx = await lotteryContract.enterLottery({ 
        value: feeInWei,
        gasLimit: 500000
      });
      
      setSuccessMsg("Transaction submitted! Waiting for confirmation...");
      await tx.wait();
      
      const numPlayers = await lotteryContract.getNumberOfPlayers();
      setPlayerCount(numPlayers.toNumber());
      
      setSuccessMsg("Successfully entered the lottery!");
    } catch (err: any) {
      console.error("Failed to enter lottery:", err);
      setErrorMsg(err.message || "Transaction failed. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="lottery-form-container">
      <h2>Enter Lottery</h2>
      
      {minFee && (
        <p className="min-fee-info">Minimum entrance fee: {minFee} ETH</p>
      )}
      
      {playerCount > 0 && (
        <p className="player-count">Current participants: {playerCount}</p>
      )}
      
      {!connectedAddress ? (
        <p className="connect-wallet-prompt">Please connect your wallet to enter</p>
      ) : (
        <>
          {errorMsg && <p className="error-message">{errorMsg}</p>}
          {successMsg && <p className="success-message">{successMsg}</p>}
          
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label htmlFor="feeInput">Enter fee to play (ETH)</label>
              <input
                id="feeInput"
                type="text"
                value={feeAmount}
                onChange={(e) => setFeeAmount(e.target.value)}
                placeholder={minFee || '0.001'}
                disabled={isSubmitting}
              />
            </div>
            
            <button 
              type="submit"
              disabled={isSubmitting || !connectedAddress}
              className="submit-button"
            >
              {isSubmitting ? "Processing..." : "Enter Lottery"}
            </button>
          </form>
        </>
      )}
    </div>
  );
};

export default FormFee;