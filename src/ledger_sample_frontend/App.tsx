import React from 'react';
import DepositWidget from './components/DepositWidget';
import ReclaimWidget from './components/ReclaimWidget';
import BalanceWidget from './components/BalanceWidget';
import { defaultProviders } from "@connect2ic/core/providers"
import { createClient } from "@connect2ic/core"
// import { Connect2ICProvider } from "@connect2ic/react"
import "@connect2ic/core/style.css"
import * as ledger_sample_backend from "../declarations/ledger_sample_backend"
import { ConnectButton, ConnectDialog, Connect2ICProvider, useConnect } from "@connect2ic/react"
import { Transfer } from "./components/Transfer"
import { Profile } from "./components/Profile"
import './main.css';


const client = createClient({
  canisters: {
    ledger_sample_backend,
  },
  providers: defaultProviders as any,
  // globalProviderConfig: {
  //   dev: import.meta.env.DEV,
  // },
})

const AppRoot = () => (
  <Connect2ICProvider client={client}>
    <App />
  </Connect2ICProvider>
)

const App = () => {
  const { isConnected, principal, activeProvider } = useConnect({
    onConnect: () => {
      // Signed in
    },
    onDisconnect: () => {
      // Signed out
    }
  })
  // These functions would be implemented to interact with your backend
  const depositICP = async (amount: string) => {
    const numericAmount = Number(amount);
    console.log('Depositing ICP:', numericAmount);
    // Call backend method to deposit ICP with numericAmount
  };

  const reclaimICP = async () => {
    console.log('Reclaiming ICP');
    // Call backend method to reclaim ICP
  };

  return (    
    <div>
      <div className="connect-button-container">
        <ConnectButton />
      </div>
      <DepositWidget onDeposit={depositICP} />
      <ReclaimWidget onReclaim={reclaimICP} />
      <BalanceWidget />      
      <ConnectDialog dark={false} />
      <p className="examples-title">
        Examples
      </p>
      <div className="examples">
        <Profile />
        <Transfer />
      </div>  
    </div>             
  );
};

export default AppRoot;