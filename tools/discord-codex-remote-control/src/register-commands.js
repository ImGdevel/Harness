const { REST, Routes } = require('discord.js');
const { commands } = require('./commands');
const { loadConfig } = require('./config');

async function main() {
  const config = loadConfig({ requireBot: true });
  const rest = new REST({ version: '10' }).setToken(config.token);
  const body = commands.map((command) => command.toJSON());

  const route = config.guildId
    ? Routes.applicationGuildCommands(config.clientId, config.guildId)
    : Routes.applicationCommands(config.clientId);

  const scope = config.guildId ? `guild ${config.guildId}` : 'global';
  console.log(`Registering ${body.length} slash command(s) for ${scope}.`);

  const registered = await rest.put(route, { body });
  console.log(`Registered ${registered.length} slash command(s).`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

