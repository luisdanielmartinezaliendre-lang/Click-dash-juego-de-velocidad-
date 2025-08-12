<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Juego Simplificado Mejorado</title>
<style>
  body, html {
    margin: 0; padding: 0; height: 100%;
    background: #a7c7e7; /* azul claro */
    display: flex;
    justify-content: center;
    align-items: center;
    font-family: Arial, sans-serif;
    user-select: none;
  }
  #container {
    width: 90vw; max-width: 400px;
    height: 90vh;
    background: white;
    border-radius: 12px;
    box-shadow: 0 0 15px rgba(0,0,0,0.2);
    display: flex; flex-direction: column;
    padding: 20px;
    box-sizing: border-box;
  }
  .screen {
    flex: 1;
    display: none;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    text-align: center;
  }
  .active { display: flex; }
  button {
    padding: 12px 24px;
    border: none;
    border-radius: 10px;
    background: #1a73e8;
    color: white;
    font-size: 1.2rem;
    cursor: pointer;
    margin-top: 15px;
  }
  button:disabled {
    background: #aaa;
    cursor: default;
  }
  #game-area {
    position: relative;
    flex: 1;
    margin-top: 20px;
    border: 2px solid #1a73e8;
    border-radius: 10px;
    background: #d0e4fd;
    overflow: hidden;
    min-height: 250px;
    min-width: 250px;
  }
  #target {
    position: absolute;
    width: 70px;
    height: 70px;
    background: #1a73e8;
    border-radius: 12px;
    cursor: pointer;
  }
  #info {
    font-size: 1.1rem;
    margin-bottom: 10px;
    color: #333;
  }
</style>
</head>
<body>
  <div id="container">
    <section id="start-screen" class="screen active">
      <h2>Atrapa el bloque</h2>
      <p>3 niveles: haz los clics necesarios antes que termine el tiempo.</p>
      <button id="start-btn">Comenzar</button>
    </section>

    <section id="game-screen" class="screen">
      <div id="info">Nivel <span id="level-num">1</span> | Tiempo: <span id="time-left">10</span>s | Objetivo: <span id="goal">5</span> clics</div>
      <div id="game-area" aria-label="Área de juego" role="main">
        <div id="target" role="button" tabindex="0"></div>
      </div>
      <div id="score-display" style="margin-top:12px;">Puntaje: 0</div>
    </section>

    <section id="retry-screen" class="screen">
      <h3>¡No alcanzaste el objetivo!</h3>
      <p>Objetivo: <span id="goal-fail">0</span> clics</p>
      <p>Tu puntaje: <span id="fail-score">0</span></p>
      <p>Precisión motora: <span id="accuracy">0</span>%</p>
      <p id="wait-timer">Puedes intentar de nuevo en 5 segundos</p>
      <button id="retry-btn" disabled>Intentar de nuevo</button>
    </section>

    <section id="end-screen" class="screen">
      <h3>¡Felicidades! Has ganado el juego.</h3>
      <p>Tu puntaje final: <span id="final-score">0</span></p>
      <p>Precisión motora: <span id="final-accuracy">0</span>%</p>
      <p id="wait-timer-win">Puedes reiniciar el juego en 5 segundos</p>
      <button id="restart-btn" disabled>Jugar otra vez</button>
    </section>
  </div>

<script>
  const startScreen = document.getElementById('start-screen');
  const gameScreen = document.getElementById('game-screen');
  const retryScreen = document.getElementById('retry-screen');
  const endScreen = document.getElementById('end-screen');

  const startBtn = document.getElementById('start-btn');
  const retryBtn = document.getElementById('retry-btn');
  const restartBtn = document.getElementById('restart-btn');

  const target = document.getElementById('target');
  const gameArea = document.getElementById('game-area');

  const levelNum = document.getElementById('level-num');
  const timeLeftDisplay = document.getElementById('time-left');
  const goalDisplay = document.getElementById('goal');
  const scoreDisplay = document.getElementById('score-display');

  const goalFail = document.getElementById('goal-fail');
  const failScore = document.getElementById('fail-score');
  const accuracyDisplay = document.getElementById('accuracy');
  const waitTimerDisplay = document.getElementById('wait-timer');

  const finalScore = document.getElementById('final-score');
  const finalAccuracy = document.getElementById('final-accuracy');
  const waitTimerWin = document.getElementById('wait-timer-win');

  let level = 1;
  const maxLevel = 3;
  const levelTimes = [10, 15, 20]; // segundos
  const levelGoals = [5, 10, 15];  // clics objetivo

  let timeLeft = 0;
  let score = 0;
  let timerId = null;
  let waitTimerId = null;
  let waitSeconds = 5;

  const minClickInterval = 300; // ms para calcular precisión

  function showScreen(screen) {
    [startScreen, gameScreen, retryScreen, endScreen].forEach(s => s.classList.remove('active'));
    screen.classList.add('active');
  }

  function moveTarget() {
    const containerWidth = gameArea.clientWidth;
    const containerHeight = gameArea.clientHeight;

    if (containerWidth === 0 || containerHeight === 0) {
      setTimeout(moveTarget, 100);
      return;
    }

    const maxX = containerWidth - target.offsetWidth;
    const maxY = containerHeight - target.offsetHeight;

    const x = Math.random() * maxX;
    const y = Math.random() * maxY;

    target.style.left = x + 'px';
    target.style.top = y + 'px';
  }

  function updateTimer() {
    timeLeft--;
    timeLeftDisplay.textContent = timeLeft;
    if (timeLeft <= 0) {
      finishOrRetry();
    }
  }

  function calculateAccuracy() {
    const maxClicksPossible = Math.floor(levelTimes[level - 1] * 1000 / minClickInterval);
    let acc = Math.round((score / maxClicksPossible) * 100);
    if (acc > 100) acc = 100;
    return acc;
  }

  function finishOrRetry() {
    clearInterval(timerId);
    if (score >= levelGoals[level - 1]) {
      if (level < maxLevel) {
        level++;
        startLevel();
      } else {
        showWin();
      }
    } else {
      showRetry();
    }
  }

  function showRetry() {
    goalFail.textContent = levelGoals[level - 1];
    failScore.textContent = score;
    accuracyDisplay.textContent = calculateAccuracy();

    waitSeconds = 5;
    waitTimerDisplay.textContent = `Puedes intentar de nuevo en ${waitSeconds} segundos`;
    retryBtn.disabled = true;

    showScreen(retryScreen);

    waitTimerId = setInterval(() => {
      waitSeconds--;
      waitTimerDisplay.textContent = `Puedes intentar de nuevo en ${waitSeconds} segundos`;
      if (waitSeconds <= 0) {
        clearInterval(waitTimerId);
        retryBtn.disabled = false;
        waitTimerDisplay.textContent = '¡Ya puedes intentar de nuevo!';
      }
    }, 1000);
  }

  function showWin() {
    finalScore.textContent = score;
    finalAccuracy.textContent = calculateAccuracy();

    waitSeconds = 5;
    waitTimerWin.textContent = `Puedes reiniciar el juego en ${waitSeconds} segundos`;
    restartBtn.disabled = true;

    showScreen(endScreen);

    waitTimerId = setInterval(() => {
      waitSeconds--;
      waitTimerWin.textContent = `Puedes reiniciar el juego en ${waitSeconds} segundos`;
      if (waitSeconds <= 0) {
        clearInterval(waitTimerId);
        restartBtn.disabled = false;
        waitTimerWin.textContent = '¡Ya puedes reiniciar el juego!';
      }
    }, 1000);
  }

  function startLevel() {
    score = 0;
    timeLeft = levelTimes[level - 1];
    levelNum.textContent = level;
    timeLeftDisplay.textContent = timeLeft;
    goalDisplay.textContent = levelGoals[level - 1];
    scoreDisplay.textContent = 'Puntaje: 0';
    showScreen(gameScreen);

    moveTarget();

    clearInterval(timerId);
    timerId = setInterval(updateTimer, 1000);
  }

  function beepSound() {
    try {
      const ctx = new AudioContext();
      const osc = ctx.createOscillator();
      osc.frequency.value = 440;
      osc.connect(ctx.destination);
      osc.start();
      setTimeout(() => {
        osc.stop();
        ctx.close();
      }, 100);
    } catch(e) {}
  }

  function onClickTarget() {
    score++;
    scoreDisplay.textContent = `Puntaje: ${score}`;
    moveTarget();
    beepSound();
  }

  startBtn.onclick = () => { level = 1; startLevel(); };
  retryBtn.onclick = () => startLevel();
  restartBtn.onclick = () => { level = 1; startLevel(); };

  target.onclick = onClickTarget;
  target.ontouchstart = (e) => { e.preventDefault(); onClickTarget(); };

  window.onresize = () => {
    if (gameScreen.classList.contains('active')) {
      moveTarget();
    }
  };
</script>
</body>
</html>