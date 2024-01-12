import React, {useState} from 'react';
import ReclaimToCallerWidget from './components/ReclaimToCallerWidget';
import ReclaimToAdminWidget from './components/ReclaimToAdminWidget';
import CanisterBalanceWidget from './components/CanisterBalanceWidget';
import CanisterDepositsWidget from './components/CanisterDepositsWidget';
import { defaultProviders } from "@connect2ic/core/providers"
import { createClient } from "@connect2ic/core"
// import { Connect2ICProvider } from "@connect2ic/react"
import "@connect2ic/core/style.css"
import * as ledger_sample_backend from "../declarations/ledger_sample_backend"
import { ConnectButton, ConnectDialog, Connect2ICProvider, useConnect } from "@connect2ic/react"
import { DepositToCanister } from "./components/DepositToCanister"
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
  const [showWalletWidgets, setShowWalletWidgets] = useState(false);
  const { isConnected, principal, activeProvider } = useConnect({
    onConnect: () => {
      // Signed in
      setShowWalletWidgets(true);
      console.log("onConnect() called");
    },
    onDisconnect: () => {
      // Signed out
      setShowWalletWidgets(false);
      console.log("onDisconnect() called");
    }
  })

  const handleReclaimSuccess = (response: string) => {
    // Logic to handle success response
    alert(`Reclaim Success: ${response}`);
  };

  const handleReclaimError = (error: string) => {
    // Logic to handle error response
    alert(`Reclaim Error: ${error}`);
  };

  return (
    <div>
      <div className="connect-button-container">
        <ConnectButton />
      </div>
      <p className="ledger-sample-title">
        <h1>Ledger Sample</h1>
      </p>
      {showWalletWidgets && (
        <div className="wallet-dependent-widgets">      
        <DepositToCanister />
        <Profile />
        <ReclaimToCallerWidget onReclaimSuccess={handleReclaimSuccess} onReclaimError={handleReclaimError} />
      </div>)}      
      <ReclaimToAdminWidget onReclaimSuccess={handleReclaimSuccess} onReclaimError={handleReclaimError} />
      <CanisterBalanceWidget />
      <CanisterDepositsWidget />
      <ConnectDialog dark={false} />
    </div>
  );
};

export default AppRoot;