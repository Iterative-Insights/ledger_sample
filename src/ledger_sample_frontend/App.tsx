import React from 'react';
import DepositWidget from './components/DepositWidget';
import ReclaimWidget from './components/ReclaimWidget';
import BalanceWidget from './components/BalanceWidget';

const App = () => {
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

  const getBalance = async () => {
    console.log('Fetching balance');
    // Call backend method to get balance
    return '10'; // Placeholder balance
  };

  return (
    <div>
      <DepositWidget onDeposit={depositICP} />
      <ReclaimWidget onReclaim={reclaimICP} />
      <BalanceWidget />
    </div>
  );
};

export default App;