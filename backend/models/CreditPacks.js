/**
 * Credit Pack Definitions
 *
 * These are the ONLY purchasable credit packs in the system.
 * Credits are NON-TRANSFERABLE, NON-REFUNDABLE, and can ONLY be used
 * for posting jobs within the KaamKaaz platform.
 *
 * RBI PPI Compliance Note:
 *   - This is a CLOSED-LOOP prepaid instrument (not a wallet).
 *   - No cash withdrawal, peer-to-peer transfer, or cross-platform usage is permitted.
 *   - Credits expire per the platform's terms and have no monetary redemption value.
 */

const CREDIT_PACKS = [
  {
    id: 'pack_starter_100',
    name: 'Starter Pack',
    priceRupees: 100,
    pricePaise: 10000,  // For Razorpay (stored in paise)
    credits: 7,         // Job posting credits granted on purchase
    description: '7 job posting credits'
  },
  {
    id: 'pack_standard_250',
    name: 'Standard Pack',
    priceRupees: 250,
    pricePaise: 25000,
    credits: 20,
    description: '20 job posting credits'
  },
  {
    id: 'pack_pro_500',
    name: 'Pro Pack',
    priceRupees: 500,
    pricePaise: 50000,
    credits: 50,
    description: '50 job posting credits'
  }
];

// Policy constants — auditable in code for compliance
const IS_REFUNDABLE = false;
const IS_TRANSFERABLE = false;
const CREDITS_USABLE_FOR = 'job_posting_only';
const CREDITS_REDEEMABLE_AS_CASH = false;

/**
 * Look up a pack by its ID.
 * Returns undefined if not found.
 */
function getPackById(packId) {
  return CREDIT_PACKS.find(p => p.id === packId);
}

module.exports = {
  CREDIT_PACKS,
  IS_REFUNDABLE,
  IS_TRANSFERABLE,
  CREDITS_USABLE_FOR,
  CREDITS_REDEEMABLE_AS_CASH,
  getPackById
};
