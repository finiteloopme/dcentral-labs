use anchor_lang::prelude::*;

declare_id!("H2LLvT2tWWPUYvN2hnNK9G6D5k5EppGzanzJFRtdAsdi");

#[program]
pub mod counter_prg {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>, count: u64) -> Result<()> {
        let counter_acc = &mut ctx.accounts.counter;
        counter_acc.count = count;
        msg!("Counter set to: {}", counter_acc.count);
        Ok(())
    }

    pub fn increment(ctx: Context<Increment>) -> Result<()> {
        let counter_acc = &mut ctx.accounts.counter;
        counter_acc.count += 1;
        msg!("Counter incremented to: {}", counter_acc.count);

        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(init, payer=user, space=8+8)]
    pub counter: Account<'info, Counter>,
    #[account(mut)]
    pub user: Signer<'info>,
    pub system_program: Program<'info, System>
}

#[derive(Accounts)]
pub struct Increment<'info> {
    #[account(mut)]
    pub counter: Account<'info, Counter>
}

#[account]
pub struct Counter{
    pub count: u64,
}
