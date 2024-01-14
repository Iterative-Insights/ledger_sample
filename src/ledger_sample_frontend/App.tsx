import React, { useState } from 'react';
import ReclaimToCallerWidget from './components/ReclaimToCallerWidget';
import ReclaimToAdminWidget from './components/ReclaimToAdminWidget';
import CanisterBalanceWidget from './components/CanisterBalanceWidget';
import CanisterDepositsWidget from './components/CanisterDepositsWidget';
import ClearAllDepositsWidget from './components/ClearAllDepositsWidget';
import { defaultProviders } from "@connect2ic/core/providers"
import { createClient } from "@connect2ic/core"

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
  const [isNotifying, setIsNotifying] = useState(false);
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

  const handleReclaim = (response: string) => {
    // Logic to handle success response
    // alert(`Reclaim Success: ${response}`);
    setEventLog(log => [...log, `Reclaim event received:  ${response}`]);
  };

  // Define the handler functions
  const handleDeposit = async (status: string, details: { height?: number, amount?: number, message?: string }): Promise<void> => {
    console.log('handleDeposit details:', details);
    if (status === 'success' && details.amount !== undefined) {
      setEventLog(log => [...log, `Deposit completed: Amount: ${details.amount}. Height: ${details.height}`]);
    } else {
      setEventLog(log => [...log, `Deposit error: ${details.message || 'Unknown error'}. Amount: ${details.amount}`]);
    }
  };

  const handleNotify = async (status: "success" | "error", details: { height?: bigint, e8sAmount?: bigint, message?: string }): Promise<void> => {
    console.log('handleNotify details:', details);
    if (status === 'success' && details.height !== undefined && details.e8sAmount !== undefined) {
      setEventLog(log => [...log, `Notification received: Block ${details.height}, e8s Amount ${details.e8sAmount}`]);
    } else {
      setEventLog(log => [...log, `Notify error: ${details.message || 'Unknown error'}`]);
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
            <ReclaimToCallerWidget afterReclaim={handleReclaim} />
          </div>)}
        <ReclaimToAdminWidget afterReclaim={handleReclaim} />
        <CanisterBalanceWidget />
        <CanisterDepositsWidget />
        <ClearAllDepositsWidget />
        <ConnectDialog dark={false} />
      </div>
      <div className="right-side-container">
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
        <div className="profile-container">
          {showWalletWidgets && <Profile />}
        </div>
      </div>
    </div>
  );
};

export default AppRoot;