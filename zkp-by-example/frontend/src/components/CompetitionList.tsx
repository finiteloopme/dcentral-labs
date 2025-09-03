import { useState, useEffect } from 'react';
import Select, { type StylesConfig } from 'react-select';
import { useNavigate } from 'react-router-dom';
import type { Competition } from '../types';
import config from '../config';

/**
 * A component that displays a searchable dropdown of available competitions.
 */
function CompetitionList() {
  const [competitions, setCompetitions] = useState<Competition[]>([]);
  const navigate = useNavigate();

  // Fetch the list of competitions from the backend when the component mounts.
  useEffect(() => {
    fetch(`${config.backendUrl}${config.api.competitions}`)
      .then(response => response.json())
      .then(data => setCompetitions(data));
  }, []);

  interface OptionType {
    value: string;
    label: string;
  }

  const options: OptionType[] = competitions.map(comp => ({
    value: comp.id,
    label: comp.name,
  }));

  const handleChange = (selectedOption: OptionType | null) => {
    if (selectedOption) {
      navigate(`/competitions/${selectedOption.value}`);
    }
  };

  const customStyles: StylesConfig<OptionType, false> = {
    control: (provided) => ({
      ...provided,
      backgroundColor: '#1a1a1a',
      borderColor: '#00ff00',
      color: '#00ff00',
    }),
    menu: (provided) => ({
      ...provided,
      backgroundColor: '#1a1a1a',
    }),
    option: (provided, state) => ({
      ...provided,
      backgroundColor: state.isSelected ? '#00ff00' : '#1a1a1a',
      color: state.isSelected ? '#000' : '#00ff00',
      ':hover': {
        backgroundColor: '#00ff00',
        color: '#000',
      },
    }),
    singleValue: (provided) => ({
      ...provided,
      color: '#00ff00',
    }),
  };

  return (
    <div>
      <h2>Select a Competition</h2>
      <Select
        options={options}
        onChange={handleChange}
        placeholder="Search for a competition..."
        styles={customStyles}
      />
    </div>
  );
}

export default CompetitionList;
