-- *************************
-- Import modules externes
-- *************************
Objet = require "lib/classic" -- import bibliothèque rxi/classic pour POO en Lua (sous license MIT - fichier license joint)

-- Si on utilise love.js pour mettre le jeu en ligne,
-- il faut désactiver l’utilisation des joysticks
-- car love.js ne les supporte pas
--
-- Are we in love.js? Joysticks are not supported there.
-- https://github.com/Davidobot/love.js/issues/74
if love.system.getOS() == "web" then
  -- Joysticks don't work in love.js
  -- https://github.com/Davidobot/love.js/issues/41
  t.modules.joystick = false
end


-- **********************************
-- Variables utilisées dans le jeu
-- *********************************

-- Constantes
LARGEUR_ECRAN = 800
HAUTEUR_ECRAN = 600
HAUTEUR_INFO = 50
NOMBRE_ASTEROIDES = 20
TEMPS_DE_JEU = 60
VITESSE_JOUEUR = 200
VITESSE_ASTEROIDES = 250
VARIO_ASTEROIDES =  150
PAUSE_RESSUSCITE = 1 

-- Variables du jeu
chrono = 0 
direction = {-1, 1}
etatJeu = 'demarrage'
multijoueureuses = false
positionInfo = {'left', 'right'}

asteroides = {}
asteroides.liste = {}

-- ***************
-- Son et images (sprites)
-- ***************

-- Sprite joueur (objet)
Joueureuse = Objet:extend()

function Joueureuse:new(pImgJoueur, pXini, pKeyUp, pKeyDown)

  self.image = love.graphics.newImage(pImgJoueur)
  self.imgExplosion = love.graphics.newImage('images/explosion.png')
  self.largeur = self.image:getWidth()
  self.hauteur = self.image:getHeight()
  self.sonMoteur = love.audio.newSource('sons/moteur.wav', 'static')
  self.sonMoteur:setLooping(true)
  self.sonExplosion = love.audio.newSource('sons/explosion.wav', 'static')
  
  self.x = pXini 
  self.y = HAUTEUR_ECRAN - self.hauteur - HAUTEUR_INFO

  self.score = 0
  self.crashes = 0
  self.vitesse = VITESSE_JOUEUR

  self.up = pKeyUp
  self.down = pKeyDown

  self.touche = false
  self.pause = PAUSE_RESSUSCITE 

end


function Joueureuse:update(dt)

  if self.touche == false then -- si le vaisseau n’est pas touché : il peut bouger
    if love.keyboard.isDown(self.up) then
      self.y = self.y - dt * self.vitesse
      self.sonMoteur:setPitch(2)
        
    elseif love.keyboard.isDown(self.down) and (self.y < HAUTEUR_ECRAN - self.hauteur - HAUTEUR_INFO) then
      self.y = self.y + dt * self.vitesse
      self.sonMoteur:setPitch(0.5)

    else
      self.sonMoteur:setPitch(1)
    
    end

  else 
    self.pause = self.pause - dt -- petite pause quand le vaisseau explose
    if self.pause <= 0 then
      self.y = HAUTEUR_ECRAN - self.hauteur - HAUTEUR_INFO -- pause finie : on replace le vaisseau en bas
      self.touche = false -- on réinitialise
      self.pause = PAUSE_RESSUSCITE
    end
  end

    -- on replace le vaisseau si d’aventure il est descendu trop bas
    if self.y > HAUTEUR_ECRAN - self.hauteur - HAUTEUR_INFO then
      self.y = HAUTEUR_ECRAN - self.hauteur - HAUTEUR_INFO
    end
    
    -- si le vaisseau a atteint le haut de l’écran on le renvoie en bas et m-à-j. score
    if (self.y + self.hauteur < 0) then
      self.score = self.score + 1
      self.y = HAUTEUR_ECRAN - self.hauteur - HAUTEUR_INFO 
    end

end


function Joueureuse:draw()

    if self.touche == false then
      love.graphics.draw(self.image, self.x, self.y)
    else
      love.graphics.draw(self.imgExplosion, self.x, self.y)
    end

end


function Joueureuse:collision()
  
  self.crashes = self.crashes + 1
  -- On gère l’explosion (+ sauvegarder dernière position joueur)
  self.touche = true
  self.sonExplosion:play()

end
   

-- Sprite étoiles
asteroides.image = love.graphics.newImage('images/asteroide.png')
asteroides.largeur = asteroides.image:getWidth()
asteroides.hauteur = asteroides.image:getHeight()

-- Police de caractère
police = love.graphics.newFont('polices/police.ttf', 20)

-- *****************
-- Fonctions
-- *****************

function testeCollision(pX1, pY1, pL1, pH1, pX2, pY2, pL2, pH2)

  return pX1 < pX2 + pL2 and pX2 < pX1 + pL1 and pY1 < pY2 + pH2 and pY2 < pY1 + pH1

end

-- ****************************
-- INITIALISATION DE LA PARTIE 
-- ****************************

function initJeu()
  
  chrono = TEMPS_DE_JEU
  etatJeu = 'en jeu'
  
  lstJoueureuses = {}

  if multijoueureuses == true then
    table.insert(lstJoueureuses, Joueureuse('images/joueureuse1.png', LARGEUR_ECRAN/3, 'up', 'down'))
    table.insert(lstJoueureuses, Joueureuse('images/joueureuse2.png', 2 * LARGEUR_ECRAN/3, 'z', 's'))
  else
    table.insert(lstJoueureuses, Joueureuse('images/joueureuse1.png', LARGEUR_ECRAN/2, 'up', 'down'))
  end

  for k, j in ipairs(lstJoueureuses) do
    j.sonMoteur:play()
  end

  -- Création des étoiles
  asteroides.liste = {} -- on vide la liste de sprites asteroides
  for n=1, NOMBRE_ASTEROIDES do
    local asteroide = {}
    asteroide.x = love.math.random(1, LARGEUR_ECRAN)
    asteroide.y = love.math.random(1, HAUTEUR_ECRAN - 2*lstJoueureuses[1].hauteur - HAUTEUR_INFO)
    asteroide.direction = direction[love.math.random(1,2)]
    asteroide.vitesse = VITESSE_ASTEROIDES - love.math.random(VARIO_ASTEROIDES)

    table.insert(asteroides.liste, asteroide)

  end

end


function love.load()
  
  love.window.setMode(LARGEUR_ECRAN, HAUTEUR_ECRAN)
  love.window.setTitle('Asteroids Race - Code Club CimeLab - Au Coin du jeu')
  love.graphics.setFont(police)

end

-- ******************
-- EVOLUTION EN JEU (update)
-- ******************

function love.update(dt)
  
  if etatJeu == 'demarrage' then

    -- selection mode 1 ou 2 joueur
    -- 
    --
  elseif etatJeu == 'en jeu' then
    
    --*******************
    -- UPDATE JEU 
    -- ******************
    if chrono > 0 then
      chrono = chrono - dt
    else
      etatJeu = 'game over'
    end

    --*****************
    -- UPDATE JOUEUREUSES
    --*****************
    
    for k, j in ipairs(lstJoueureuses) do
      j:update(dt)
    end

    --**********************
    -- UPDATE asteroideS
    --**********************

    -- on parcourt la liste des étoiles
    for index, asteroide in ipairs(asteroides.liste) do
     
      -- update position de chaque étoile
      asteroide.x = asteroide.x + dt * asteroide.direction * asteroide.vitesse
      if (asteroide.x > LARGEUR_ECRAN + asteroides.largeur) or (asteroide.x < 0 - asteroides.largeur) then
        asteroide.x = LARGEUR_ECRAN/2 - asteroide.direction * LARGEUR_ECRAN/2
      end
   
      -- teste collision de chaque étoile avec la fusée
      for k, j in ipairs(lstJoueureuses) do
        if testeCollision(asteroide.x, asteroide.y, asteroides.largeur, asteroides.hauteur, j.x, j.y, j.largeur, j.hauteur) and j.touche == false then
        j:collision()
        end
      end  
    
    end

  elseif etatJeu == 'game over' then

    for k, j in ipairs(lstJoueureuses) do
      j.sonMoteur:stop()
    end
    
  else
    etatJeu = 'demarrage'
  
  end

end 

-- ***************
-- AFFICHAGE
-- ***************
function love.draw()

  if etatJeu == 'demarrage' then

    love.graphics.printf("ASTEROIDS RACE", 0, 100, LARGEUR_ECRAN, 'center')
    
    love.graphics.printf("Choisissez le nombre de joueur-euse-s avec les flèches gauche ou droite", 20, HAUTEUR_ECRAN/2 - 80, LARGEUR_ECRAN - 20, 'center')

    if multijoueureuses == false then
      nJoueureuses = "1 joueur-euse"
    else
      nJoueureuses = "2 joueur-euse-s" 
    end
    love.graphics.printf(nJoueureuses, 0, HAUTEUR_ECRAN/2, LARGEUR_ECRAN, 'center') 

    love.graphics.printf("Pour lancer le jeu appuyer sur ‘espace‘", 20, HAUTEUR_ECRAN/2 + 50, LARGEUR_ECRAN - 20, 'center')
    love.graphics.printf("Jouez avec les touches ‘haut‘, ‘bas‘, ‘z’ et ’s’", 20, HAUTEUR_ECRAN/2 + 120, LARGEUR_ECRAN - 20, 'center')
    love.graphics.printf("À tout moment, quittez avec ’echap‘", 20, HAUTEUR_ECRAN/2 + 200, LARGEUR_ECRAN - 20, 'center')
    
  elseif etatJeu == 'en jeu' then
    
    -- *****************
    -- AFFICHAGE INFO
    -- *****************
    
    love.graphics.line(0, HAUTEUR_ECRAN - HAUTEUR_INFO, LARGEUR_ECRAN, HAUTEUR_ECRAN - HAUTEUR_INFO)
    love.graphics.printf(math.ceil(chrono), 0, HAUTEUR_ECRAN - 45, LARGEUR_ECRAN, 'center')

    -- ***********************
    -- AFFICHAGE JOUEUREUSES
    -- **********************
   
    for k, j in ipairs(lstJoueureuses) do
      j:draw()
      love.graphics.printf("Score J"..tostring(k)..":"..tostring(j.score), 10, HAUTEUR_ECRAN - 45, LARGEUR_ECRAN - 20, positionInfo[k])
      love.graphics.printf("Crashes J"..tostring(k)..":"..tostring(j.crashes), 10, HAUTEUR_ECRAN -25, LARGEUR_ECRAN - 20, positionInfo[k])

    end

    -- *********************
    -- AFFICHAGE ASTEROIDES 
    -- *********************
    
    for index, asteroide in ipairs(asteroides.liste) do
      love.graphics.draw(asteroides.image, asteroide.x, asteroide.y)
    end

  elseif etatJeu == 'game over' then
    
    for k, j in ipairs(lstJoueureuses) do
      love.graphics.printf("Score J"..tostring(k)..":"..tostring(j.score).." - Crashes J"..tostring(k)..":"..tostring(j.crashes), 0, HAUTEUR_ECRAN/2 - 100 + k*30, LARGEUR_ECRAN, 'center')
    end
    
    love.graphics.printf("‘Entrée‘ pour revenir au menu", 0, HAUTEUR_ECRAN/2 + 30, LARGEUR_ECRAN, 'center')

  end
end

-- ******************
-- TOUCHES HORS-JEU 
-- ******************
function love.keypressed(key)

  if key == 'escape' then
    love.event.quit()
  end
  
  if key == 'return' and etatJeu == 'game over' then
    etatJeu = 'demarrage'
  end

  if etatJeu == 'demarrage' then
    
    if (key == 'left') or (key == 'right') then
      multijoueureuses = not multijoueureuses
    end
    if key == 'space' then
      initJeu()
    end
  end

end
