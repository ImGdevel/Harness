const { SlashCommandBuilder } = require('discord.js');

const codexCommand = new SlashCommandBuilder()
  .setName('codex')
  .setDescription('Send tasks to the local Codex queue and manage notifications.')
  .addSubcommand((subcommand) =>
    subcommand
      .setName('task')
      .setDescription('Queue a remote Codex task.')
      .addStringOption((option) =>
        option
          .setName('prompt')
          .setDescription('Task prompt for the local Codex session.')
          .setRequired(true)
          .setMaxLength(1800),
      ),
  )
  .addSubcommand((subcommand) =>
    subcommand
      .setName('done')
      .setDescription('Send a major-work completion notification.')
      .addStringOption((option) =>
        option
          .setName('summary')
          .setDescription('Short completion summary.')
          .setRequired(true)
          .setMaxLength(300),
      )
      .addStringOption((option) =>
        option
          .setName('details')
          .setDescription('Optional details for review.')
          .setRequired(false)
          .setMaxLength(1500),
      ),
  )
  .addSubcommand((subcommand) =>
    subcommand
      .setName('status')
      .setDescription('Show local bridge status.'),
  )
  .addSubcommand((subcommand) =>
    subcommand
      .setName('threads')
      .setDescription('List recent Codex App Server threads.')
      .addIntegerOption((option) =>
        option
          .setName('limit')
          .setDescription('Number of threads to show.')
          .setRequired(false)
          .setMinValue(1)
          .setMaxValue(10),
      ),
  )
  .addSubcommand((subcommand) =>
    subcommand
      .setName('thread-set')
      .setDescription('Set the Codex thread id used by Discord follow-up tasks.')
      .addStringOption((option) =>
        option
          .setName('thread_id')
          .setDescription('Codex thread id to resume.')
          .setRequired(true)
          .setMaxLength(120),
      ),
  )
  .addSubcommand((subcommand) =>
    subcommand
      .setName('thread-new')
      .setDescription('Clear the stored Codex thread id so the next task starts a new thread.'),
  );

module.exports = {
  commands: [codexCommand],
};
