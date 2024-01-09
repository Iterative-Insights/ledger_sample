import React, { useEffect, useState } from 'react';
import { ledger_sample_backend} from '../../declarations/ledger_sample_backend';
import { GetCallerBalanceResult } from '../../declarations/ledger_sample_backend/ledger_sample_backend.did';

const BalanceWidget = () => {
  const [balance, setBalance] = useState('Loading balance...');
  const [isFetching, setIsFetching] = useState(false); // State to track if fetching is in progress

  const fetchBalance = async () => {
    setIsFetching(true);
    setBalance('Refreshing...'); // Update the balance display to "Refreshing..." during the fetch    
    try {
      const result: GetCallerBalanceResult = await ledger_sample_backend.getCanisterBalance();
      if ('ok' in result) {
        setBalance(result.ok.balance.ICP.e8s.toString()); // Adjust based on actual structure
      } else {
        setBalance('Error fetching balance');
      }
    } catch (error) {
      setBalance('Error fetching balance');
    }
    setIsFetching(false); // Re-enable the button by setting isFetching to false
  };
  
  useEffect(() => {
    fetchBalance();
  }, []);

  return (
    <div>
      <h2>Canister Current Balance</h2>
      <p>{isFetching ? 'Refreshing...' : `${balance} e8s ICP`}</p> {/* Change the display conditionally */}
      <button onClick={fetchBalance} disabled={isFetching}>
        {isFetching ? 'Refreshing...' : 'Refresh Balance'}
      </button>
    </div>
  );
};

export default BalanceWidget;