import { useState, useEffect } from 'react';
import config from '../config';
import type { Competition } from '../types';
import SudokuGrid from '../components/SudokuGrid';

function VerifyProofPage() {
  const [proof, setProof] = useState('');
  const [competitions, setCompetitions] = useState<Competition[]>([]);
  const [selectedCompetitionId, setSelectedCompetitionId] = useState<string>('');
  const [verificationResult, setVerificationResult] = useState<boolean | null>(null);
  const [score, setScore] = useState<number>(0);

  useEffect(() => {
    fetch(`${config.backendUrl}${config.api.competitions}`)
      .then(response => response.json())
      .then(data => {
        setCompetitions(data);
        if (data.length > 0) {
          setSelectedCompetitionId(data[0].id);
        }
      });
  }, []);

  const handleVerifyProof = () => {
    const selectedCompetition = competitions.find(c => c.id === selectedCompetitionId);
    if (!selectedCompetition) {
      console.error("No competition selected");
      return;
    }

    const puzzleArray = selectedCompetition.board;

    fetch(`${config.proofServiceUrl}/verify-proof`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        proof,
        puzzle: puzzleArray,
        score,
      }),
    })
      .then(response => response.json())
      .then(data => setVerificationResult(data))
      .catch(err => {
        console.error("Verification failed:", err);
        setVerificationResult(false);
      });
  };

  const selectedPuzzle = competitions.find(c => c.id === selectedCompetitionId)?.board;

  return (
    <div>
      <h2>Verify a Proof</h2>

      <label htmlFor="competition-select">Select a competition:</label>
      <select id="competition-select" value={selectedCompetitionId} onChange={e => setSelectedCompetitionId(e.target.value)}>
        {competitions.map(c => (
          <option key={c.id} value={c.id}>{c.name}</option>
        ))}
      </select>

      {selectedPuzzle && (
        <div style={{ marginTop: '20px' }}>
          <h3>Puzzle to Verify Against:</h3>
          <SudokuGrid board={selectedPuzzle} initialBoard={selectedPuzzle} onCellChange={() => {}} />
        </div>
      )}

      <div style={{ marginTop: '20px' }}>
        <input
          type="number"
          value={score}
          onChange={e => setScore(parseInt(e.target.value, 10))}
          placeholder="Enter the score"
          style={{ width: '100%' }}
        />
      </div>

      <div style={{ marginTop: '20px' }}>
        <textarea
          value={proof}
          onChange={e => setProof(e.target.value)}
          placeholder="Enter the proof (base64 encoded)"
          rows={10}
          style={{ width: '100%' }}
        />
      </div>

      <button onClick={handleVerifyProof} style={{ marginTop: '10px' }}>Verify Proof</button>

      {verificationResult !== null && (
        <div style={{ marginTop: '20px' }}>
          <h3>Verification Result:</h3>
          <p>{verificationResult ? 'Valid' : 'Invalid'}</p>
        </div>
      )}
    </div>
  );
}

export default VerifyProofPage;
