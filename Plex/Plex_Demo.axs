PROGRAM_NAME='Plex_Demo'

DEFINE_DEVICE

dvPlex = 0:3:0
dvTp = 10001:6:0

DEFINE_VARIABLE

char    plexServer[] = '192.168.188.11'
integer plexPort     = 32400
char    plexPlayer[] = 'MacMini1.local.'

DEFINE_START

DEFINE_MODULE 'Plex_Comm' Plex (dvTp,dvPlex,plexServer,plexPort,plexPlayer)

DEFINE_PROGRAM
