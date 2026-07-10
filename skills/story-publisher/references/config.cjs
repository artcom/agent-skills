// story/config.cjs — Story Publisher configuration for this app.
// BACKEND_HOST and CONFIGURATION_PATH are supplied via env vars so the file is portable:
//   export CONFIGURATION_PATH=/abs/path/to/configuration-repo/   # trailing slash!

const BACKEND_HOST = process.env.HOST;
const CONFIGURATION_PATH = process.env.CONFIGURATION_PATH;

const TOUR_CONFIGURATION = "daily_de";
const GUIDE = "backenddeveloper";
const GUIDE_DEVICE = "Dev-Device-01";
const GUIDE_DEVICE_TOPIC = `devices/${GUIDE_DEVICE}`;
const DISPLAY_DEVICE = "HM-Wall-P1"; // Key for the runStory parameter object 'displays'
const BOOTSTRAP_URI = `http://bootstrap-server.${BACKEND_HOST}/${GUIDE_DEVICE}`;

module.exports = {
  TOUR_CONFIGURATION,
  GUIDE,
  GUIDE_DEVICE,
  GUIDE_DEVICE_TOPIC,
  DISPLAY_DEVICE,
  BACKEND_HOST,
};
