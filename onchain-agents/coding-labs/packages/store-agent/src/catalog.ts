export interface StationeryItem {
  id: string;
  name: string;
  description: string;
  category: 'notebooks' | 'pens' | 'pencils' | 'erasers' | 'markers' | 'paper' | 'accessories';
  priceUSDC: string;    // Human-readable price, e.g., "2.50"
  priceRaw: string;     // Raw USDC amount in smallest unit (6 decimals), e.g., "2500000"
  inStock: boolean;
}

export const CATALOG: StationeryItem[] = [
  {
    id: 'notebook-spiral',
    name: 'Spiral Notebook',
    description: 'Classic 100-page spiral-bound notebook. College ruled. Perfect for notes and sketches.',
    category: 'notebooks',
    priceUSDC: '2.50',
    priceRaw: '2500000',
    inStock: true,
  },
  {
    id: 'notebook-leather',
    name: 'Leather Journal',
    description: 'Premium leather-bound journal with 200 blank pages. Great for journaling.',
    category: 'notebooks',
    priceUSDC: '12.00',
    priceRaw: '12000000',
    inStock: true,
  },
  {
    id: 'pen-gel-set',
    name: 'Gel Pen Set (5-pack)',
    description: 'Smooth-writing gel pens in black, blue, red, green, and purple.',
    category: 'pens',
    priceUSDC: '5.00',
    priceRaw: '5000000',
    inStock: true,
  },
  {
    id: 'pen-fountain',
    name: 'Classic Fountain Pen',
    description: 'Elegant fountain pen with fine nib. Includes ink cartridge.',
    category: 'pens',
    priceUSDC: '15.00',
    priceRaw: '15000000',
    inStock: true,
  },
  {
    id: 'pencil-mechanical',
    name: 'Mechanical Pencil (0.5mm)',
    description: 'Precision mechanical pencil with rubber grip. Includes lead refills.',
    category: 'pencils',
    priceUSDC: '1.50',
    priceRaw: '1500000',
    inStock: true,
  },
  {
    id: 'pencil-set-hb',
    name: 'HB Pencil Set (12-pack)',
    description: 'Standard HB graphite pencils. Pre-sharpened and ready to use.',
    category: 'pencils',
    priceUSDC: '3.00',
    priceRaw: '3000000',
    inStock: true,
  },
  {
    id: 'eraser-pack',
    name: 'Eraser Pack (3-pack)',
    description: 'Soft white erasers that erase cleanly without smudging.',
    category: 'erasers',
    priceUSDC: '0.75',
    priceRaw: '750000',
    inStock: true,
  },
  {
    id: 'highlighter-set',
    name: 'Highlighter Set (4-pack)',
    description: 'Bright highlighters in yellow, pink, green, and orange. Chisel tip.',
    category: 'markers',
    priceUSDC: '3.00',
    priceRaw: '3000000',
    inStock: true,
  },
  {
    id: 'paper-a4-ream',
    name: 'A4 Paper Ream (500 sheets)',
    description: 'Premium white A4 paper, 80gsm. Suitable for printing and writing.',
    category: 'paper',
    priceUSDC: '8.00',
    priceRaw: '8000000',
    inStock: true,
  },
  {
    id: 'sticky-notes',
    name: 'Sticky Notes (3x3 inch, 100 sheets)',
    description: 'Self-adhesive notes in bright yellow. Repositionable.',
    category: 'paper',
    priceUSDC: '1.25',
    priceRaw: '1250000',
    inStock: true,
  },
  {
    id: 'ruler-30cm',
    name: 'Clear Ruler (30cm)',
    description: 'Transparent plastic ruler with metric and imperial markings.',
    category: 'accessories',
    priceUSDC: '0.50',
    priceRaw: '500000',
    inStock: true,
  },
  {
    id: 'scissors-office',
    name: 'Office Scissors',
    description: 'Stainless steel scissors with comfortable grip. 8-inch.',
    category: 'accessories',
    priceUSDC: '4.00',
    priceRaw: '4000000',
    inStock: true,
  },
];

// Helper functions
export function findItemById(id: string): StationeryItem | undefined {
  return CATALOG.find(item => item.id === id);
}

export function findItemByName(name: string): StationeryItem | undefined {
  const lower = name.toLowerCase();
  return CATALOG.find(item => item.name.toLowerCase().includes(lower));
}

export function getItemsByCategory(category: string): StationeryItem[] {
  return CATALOG.filter(item => item.category === category.toLowerCase());
}

export function searchItems(query: string): StationeryItem[] {
  const lower = query.toLowerCase();
  return CATALOG.filter(
    item =>
      item.name.toLowerCase().includes(lower) ||
      item.description.toLowerCase().includes(lower) ||
      item.category.includes(lower)
  );
}
