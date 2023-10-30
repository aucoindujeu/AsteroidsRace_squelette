-- ***************
-- Game variables
-- ***************

-- Constantes
LARGEUR_ECRAN = 800
HAUTEUR_ECRAN = 600
HAUTEUR_INFO = 50
NOMBRE_ASTEROIDES = 20
TEMPS_DE_JEU = 60
VITESSE_JOUEUR = 200
VITESSE_ASTEROIDES = 250
VARIO_ASTEROIDES =  150
PAUSE_RESSUSCITE = 10

-- Variables du jeu
chrono = 0 
direction = {-1, 1}
etatJeu = 'demarrage'

joueur = {}
joueur.score = 0
joueur.tentatives = 0
joueur.vitesse = VITESSE_JOUEUR
joueur.touche = false
joueur.pause = PAUSE_RESSUSCITE 
asteroides = {}
asteroides.liste = {}

-- ***************
-- Son et images (sprites)
-- ***************

-- Sprite joueur
joueur.image = love.graphics.newImage('joueur.png')
joueur.imgExplosion = love.graphics.newImage('explosion.png')
joueur.largeur = joueur.image:getWidth()
joueur.hauteur = joueur.image:getHeight()
joueur.sonMoteur = love.audio.newSource('moteur.wav', 'static')
joueur.sonMoteur:setLooping(true)
joueur.sonExplosion = love.audio.newSource('explosion.wav', 'static')

-- Sprite étoiles
asteroides.image = love.graphics.newImage('asteroide.png')
asteroides.largeur = asteroides.image:getWidth()
asteroides.hauteur = asteroides.image:getHeight()

-- Police de caractère
police = love.graphics.newFont('police.ttf', 20)

-- *****************
-- Fonctions
-- *****************

function testeCollision(pX1, pY1, pL1, pH1, pX2, pY2, pL2, pH2)

  return pX1 < pX2 + pL2 and pX2 < pX1 + pL1 and pY1 < pY2 + pH2 and pY2 < pY1 + pH1

end


function initJeu()
  
  chrono = TEMPS_DE_JEU
  etatJeu = 'en jeu'
  joueur.x = (LARGEUR_ECRAN - joueur.largeur)/2
  joueur.y = HAUTEUR_ECRAN - joueur.hauteur - HAUTEUR_INFO
  joueur.sonMoteur:play()
  joueur.score = 0

  -- Création des étoiles
  asteroides.liste = {} -- on vide la liste de sprites asteroides
  for n=1, NOMBRE_ASTEROIDES do
    local asteroide = {}
    asteroide.x = love.math.random(1, LARGEUR_ECRAN)
    asteroide.y = love.math.random(1, HAUTEUR_ECRAN - 2*joueur.hauteur - HAUTEUR_INFO)
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
    -- UPDATE JOUEUR
    --*****************
    
    if (joueur.y + joueur.hauteur < 0) then
      joueur.score = joueur.score + 1
      joueur.y = HAUTEUR_ECRAN - joueur.hauteur - HAUTEUR_INFO 
    end
    if joueur.touche == false then 
      if love.keyboard.isDown('up') then
        joueur.y = joueur.y - dt*joueur.vitesse
        joueur.sonMoteur:setPitch(2)
        
      elseif love.keyboard.isDown('down') and (joueur.y < HAUTEUR_ECRAN - joueur.hauteur - HAUTEUR_INFO) then
        joueur.y = joueur.y + dt*joueur.vitesse
        joueur.sonMoteur:setPitch(0.5)

      else
        joueur.sonMoteur:setPitch(1)
      end
    end

    -- on replace le joueur si d’avenure il est descendu trop bas
    if joueur.y > HAUTEUR_ECRAN - joueur.hauteur - HAUTEUR_INFO then
      joueur.y = HAUTEUR_ECRAN - joueur.hauteur - HAUTEUR_INFO
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
      if testeCollision(asteroide.x, asteroide.y, asteroides.largeur, asteroides.hauteur, joueur.x, joueur.y, joueur.largeur, joueur.hauteur) and joueur.touche == false then
        joueur.tentatives = joueur.tentatives + 1
        -- On gère l’explosion (+ sauvegarder dernière position joueur)
        joueur.touche = true
        joueur.sonExplosion:play()
      end
      if joueur.touche == true then
        joueur.pause = joueur.pause - dt
        if joueur.pause <= 0 then
          joueur.y = HAUTEUR_ECRAN - joueur.hauteur - HAUTEUR_INFO
          joueur.touche = false
          joueur.pause = PAUSE_RESSUSCITE
        end
      end

    end

  elseif etatJeu == 'game over' then

    joueur.sonMoteur:stop()
    
  else
    etatJeu = 'demarrage'
  
  end

end 

function love.draw()

  if etatJeu == 'demarrage' then
    love.graphics.printf("Pour lancer le jeu appuyer sur espace", 0, HAUTEUR_ECRAN/2, LARGEUR_ECRAN, 'center')

  elseif etatJeu == 'en jeu' then
    
    -- *****************
    -- AFFICHAGE INFO
    -- *****************
    love.graphics.line(0, HAUTEUR_ECRAN - HAUTEUR_INFO, LARGEUR_ECRAN, HAUTEUR_ECRAN - HAUTEUR_INFO)
    love.graphics.print("Score:"..tostring(joueur.score), 10, HAUTEUR_ECRAN - 45)
    love.graphics.print("Tentatives:"..tostring(joueur.tentatives), 10, HAUTEUR_ECRAN -25)
    love.graphics.printf(math.ceil(chrono), 0, HAUTEUR_ECRAN - 45, LARGEUR_ECRAN, 'center')

    -- *****************
    -- AFFICHAGE JOUEUR
    -- *****************
    if joueur.touche == false then
      love.graphics.draw(joueur.image, joueur.x, joueur.y)
    else
      love.graphics.draw(joueur.imgExplosion, joueur.x, joueur.y)
    end
    -- *****************
    -- AFFICHAGE asteroideS 
    -- *****************
    for index, asteroide in ipairs(asteroides.liste) do
      love.graphics.draw(asteroides.image, asteroide.x, asteroide.y)
    end

  elseif etatJeu == 'game over' then
    
    love.graphics.printf("Score :"..tostring(joueur.score).." Tentatives :"..tostring(joueur.tentatives), 0, HAUTEUR_ECRAN/2, LARGEUR_ECRAN, 'center')
    love.graphics.printf("Entrée pour revenir au menu", 0, HAUTEUR_ECRAN/2 + 30, LARGEUR_ECRAN, 'center')
  end
end


function love.keypressed(key)

  if key == 'escape' then
    love.event.quit()
  end
  
  if key == 'return' and etatJeu == 'game over' then
    etatJeu = 'demarrage'
  end

  if key == 'space' and etatJeu == 'demarrage' then
    initJeu()
  end

end
