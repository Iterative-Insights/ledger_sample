import React, { useState } from 'react';
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
  const [eventLog, setEventLog] = useState<string[]>([]);
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
    // alert(`Reclaim Success: ${response}`);
    setEventLog(log => [...log, `Reclaim success received:  ${response}`]);
  };

  const handleReclaimError = (error: string) => {
    // Logic to handle error response
    // alert(`Reclaim Error: ${error}`);
    setEventLog(log => [...log, `Reclaim error received:  ${error}`]);
  };

  // Define the handler functions
  const handleDeposit = async (status: string, info: { amount: number }): Promise<void> => {
    if (status === 'success') {
      setEventLog(log => [...log, `Deposit completed: Amount ${info.amount}`]);
    } else {
      setEventLog(log => [...log, `Deposit error: ${info}`]);
    }
  };

  const handleNotify = async (status: string, info: { blockHeight: number, amount: bigint } | string) => {
    if (status === 'success' && typeof info === 'object' && 'blockHeight' in info) {
      setEventLog(log => [...log, `Notification received: Block ${info.blockHeight}, Amount ${info.amount}`]);
    } else {
      setEventLog(log => [...log, `Notify error: ${info}`]);
    }
  };

  return (
    <div className="app-container">
      <div className="main-content">
        <div className="connect-button-container">
          <ConnectButton />
        </div>
        <p className="ledger-sample-title">
          <h1>Ledger Sample</h1>
        </p>
        {showWalletWidgets && (
          <div className="wallet-dependent-widgets">
            <DepositToCanister afterDeposit={handleDeposit} afterNotify={handleNotify} />
            <Profile />
            <ReclaimToCallerWidget onReclaimSuccess={handleReclaimSuccess} onReclaimError={handleReclaimError} />
          </div>)}
        <ReclaimToAdminWidget onReclaimSuccess={handleReclaimSuccess} onReclaimError={handleReclaimError} />
        <CanisterBalanceWidget />
        <CanisterDepositsWidget />
        <ConnectDialog dark={false} />
      </div>
      <div className="event-log-container">
        {
          <div className="event-log">
            <h2>Event Log</h2>
            <ul>
              {eventLog.map((entry, index) => (
                <li key={index}>{entry}</li>
              ))}
            </ul>
          </div>
        }
      </div>
    </div>
  );
};

export default AppRoot;