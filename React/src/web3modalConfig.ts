// web3modalConfig.ts
import { ethers } from 'ethers';
import Web3Modal from 'web3modal';
import WalletConnectProvider from '@walletconnect/web3-provider';

const INFURA_ID = '';

const providerOptions = {
  walletconnect: {
    package: WalletConnectProvider,
    options: {
      infuraId: INFURA_ID,
    },
  },
};

let web3Modal: Web3Modal | null = null;

if (typeof window !== 'undefined') {
  web3Modal = new Web3Modal({
    cacheProvider: true,
    providerOptions,
    theme: 'dark',
  });
}

export const connectWallet = async () => {
  if (!web3Modal) throw new Error("Web3Modal not initialized");

  const provider = await web3Modal.connect();
  const ethersProvider = new ethers.providers.Web3Provider(provider);

  provider.on("accountsChanged", () => window.location.reload());
  provider.on("chainChanged", () => window.location.reload());

  return ethersProvider;
};

export const disconnectWallet = async () => {
  if (web3Modal) {
    await web3Modal.clearCachedProvider();
  }
};

export const checkConnection = async () => {
  if (web3Modal && web3Modal.cachedProvider) {
    return await connectWallet();
  }
  return null;
};