import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";
import { timeAttackConfig } from "./config/timeAttackConfig";

initializeApp();
setGlobalOptions({
  region: timeAttackConfig.region,
  maxInstances: 2,
});

export { startTimeAttackRun } from "./time_attack/startTimeAttackRun";
export { submitTimeAttackRun } from "./time_attack/submitTimeAttackRun";
export { setPlayerName } from "./time_attack/setPlayerName";
export { syncVsQuantumWins } from "./vs/syncVsQuantumWins";
