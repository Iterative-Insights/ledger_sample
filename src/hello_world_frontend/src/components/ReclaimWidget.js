import React from 'react';

const ReclaimWidget = ({ onReclaim }) => {
  const handleReclaim = async () => {
    await onReclaim();
  };

  return (
    <div>
      <h2>Reclaim ICP</h2>
      <button onClick={handleReclaim}>Reclaim</button>
    </div>
  );
};

export default ReclaimWidget;