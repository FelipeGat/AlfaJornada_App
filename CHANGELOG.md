## AlfaMobi — 22/07/2026 — Home do morador com cara de app premium

- Início com foto do condomínio e um resumo do que precisa da sua atenção
- Comunicados agora mostram quando chegaram (Hoje/Ontem) e destacam o que
  ainda não foi lido
- Nova linha do tempo com a atividade recente (encomendas e acessos, tudo
  num só lugar)
- Aba "Módulos" virou "Serviços", agora organizada por categoria (Segurança,
  Condomínio, Minha unidade)

## AlfaMobi — 17/07/2026 — Correção na permissão de instalação da atualização

- Corrige "pacote parece ser inválido" ao instalar a atualização em alguns
  aparelhos (faltava a permissão do Android pro app instalar o próprio APK
  baixado — mais comum em Xiaomi/MIUI, que mostra esse erro genérico em vez
  de avisar sobre a permissão)

## AlfaMobi — 17/07/2026 — Correção no download de atualizações

- Corrige instalação falhando com "pacote inválido" quando a conexão cai
  durante o download da atualização (agora detecta e pede pra tentar de novo)

## AlfaMobi — 17/07/2026 — Histórico de comunicados, grupos e convite de morador

- Comunicados: veja o histórico de edições (o que mudou, quem editou, quando)
- Documentos: pastas agora podem ser restritas a um grupo específico
- Convidar morador: gere o link de acesso direto pela ficha da pessoa
- Correção no sistema de atualização automática (canal próprio do Condomínio)

## AlfaMobi — 17/07/2026 — 8 módulos novos de Condomínio

- Comunicados: avisos do síndico com confirmação de leitura
- Reservas: área comum (churrasqueira, salão) com calendário e aprovação
- Enquetes: vote e acompanhe o resultado em tempo real
- Fórum: converse com outros moradores sobre o dia a dia do condomínio
- Documentos: atas, editais e convenção organizados por pasta
- Pets: cadastre o bichinho de estimação com foto e carteira de vacinação
- Autorizações e Entregas: melhorias no controle de acesso da portaria

## AlfaMobi — 17/07/2026 — Home do morador ganha mais vida

- Banner com a notificação mais recente (ex.: "sua encomenda chegou")
- Botão "+" agora abre as 4 ações rápidas (antes só tinha 2)
- Animação suave de entrada nas seções da Home

## AlfaMobi — 16/07/2026 — Home do morador (AlfaControl) reformulada

- Cabeçalho mostra nome do condomínio/empresa, apartamento/bloco e último acesso
- "Minha unidade" virou "Meu Prédio"/"Meu Escritório", com foto da fachada
- Nova seção "Atividade recente" junta acessos e encomendas num único feed
- Liberação de QR Code para visitantes voltou a ficar disponível pro morador
- Cards de status mostram texto (ex.: "Nenhuma encomenda") em vez de "0"

## AlfaMobi — 17/07/2026 — Unificação Academia + Condomínio numa única versão

Academia e Condomínio vinham publicando atualizações em canais separados, mas o AlfaMobi é um único binário com as features dos dois produtos — o que causou uma publicação saída com o certificado de assinatura errado (debug em vez de release), quebrando a instalação da atualização para quem já tinha o app. Esta versão junta todo o trabalho dos dois lados (features de Condomínio + as correções e novidades de Academia listadas abaixo) numa única build, assinada com o certificado oficial e verificada antes de publicar.

## AlfaMobi — 17/07/2026 — UsuarioApp: detalhe do treino abre, histórico funciona e trocar foto no perfil

Esta versão fecha três pontos que apareceram no teste real do UsuarioApp: abrir os exercícios de um treino, ver o histórico de treinos e trocar a foto do perfil.

### Novidades

- **Trocar foto de perfil no UsuarioApp**: agora o ícone da câmera na tela de Editar Perfil abre um seletor com as opções "Tirar foto" e "Escolher da galeria". A foto é enviada ao servidor imediatamente e o avatar em toda parte do app (Home, Menu, cabeçalho) reflete a mudança sem precisar deslogar.

### Correções

- **Detalhe do treino do UsuarioApp voltou a abrir**: ao clicar num treino, a tela dava "Resposta inválida do servidor". A resposta do servidor não estava no formato que o app espera para exibir os exercícios da ficha; agora está — a tela abre com todos os exercícios listados, séries, repetições, descanso e observações que você registrou.

- **"Histórico de treinos" do UsuarioApp voltou a funcionar**: a tela dava "Sem permissão" porque o app estava chamando o endereço de servidor do outro tipo de usuário. Agora ele decide dinamicamente qual endereço usar e o histórico abre normalmente (vazio, porque a persistência de sessões executadas entra em outra fase).

## AlfaMobi — 17/07/2026 — Correção crítica: UsuarioApp voltou a enxergar treinos, agenda e histórico

Esta versão corrige um problema que fazia com que quem usa o app público (sem vínculo com academia) — mesmo após atualizar para versões recentes — continuasse vendo "Nenhum treino ainda" ou "Sem permissão" em áreas onde deveria haver conteúdo.

### Correções

- **UsuarioApp voltou a ver os próprios treinos, agenda e histórico**: o app decide em tempo real qual canal do servidor consultar (o do aluno de academia ou o do usuário público). Essa decisão vinha sendo tomada com base num campo salvo localmente que, em versões antigas do app, ficava vazio — quem atualizou de uma versão bem antiga para as mais novas continuava caindo no canal errado e batia em endpoints protegidos, recebendo "Sem permissão" ou "Nenhum treino". A partir desta versão, o app decide o canal lendo diretamente o perfil do próprio token de autenticação, que é sempre atualizado — imune a resquícios de versões anteriores. Efeito imediato: treinos, agenda pessoal, avaliações e histórico voltam a aparecer normalmente após reabrir o app.

## AlfaMobi — 17/07/2026 — Correções UsuarioApp: endpoints alinhados, editar perfil com endereço separado e lembretes de hidratação

Esta versão fecha um conjunto de correções que apareceram durante o teste real de uma UsuarioApp: endpoints que davam "endpoint não encontrado" ou "sem permissão" pra recursos que já estavam disponíveis, editar perfil que não persistia, botões de novo treino e nova avaliação com texto quebrando em telas menores, e a chegada dos lembretes automáticos de beber água.

### Novidades

- **Lembretes de hidratação com notificações locais**: o AlfaMobi agora consegue avisar você de tempos em tempos para beber água. Um novo botão de sino aparece na tela de Hidratação (Bem-estar) — abre um diálogo onde você escolhe se quer receber lembretes, com qual intervalo (1h, 2h, 3h ou 4h) e a janela do dia em que quer ser lembrado (por padrão das 8h às 20h). As notificações são locais no aparelho, funcionam mesmo sem sinal, e a permissão é pedida apenas quando você ativa. Meta de água padrão passa a ser 3 litros (antes eram 2,5 litros), mais aderente à recomendação geral.

### Correções

- **Editar perfil deixou de dar "endpoint não encontrado"**: quem usa o app público (sem vínculo com academia) agora tem seu próprio caminho de atualização de perfil, que aceita nome, telefone e endereço completo separado em campos (CEP, logradouro, número, complemento, bairro, cidade e UF). Antes o app tentava salvar num endpoint que não existia; agora salva corretamente e mostra os dados de volta na próxima vez que a tela abre.

- **"Minha agenda" do UsuarioApp voltou a funcionar**: a tela dava "endpoint não encontrado" porque o caminho no servidor tinha sido escrito diferente entre o app e o backend. Com o mesmo caminho dos dois lados, criar, editar e marcar aulas pessoais como feitas voltou a funcionar.

- **"Histórico de treinos" do UsuarioApp deixou de dar "sem permissão"**: o servidor agora responde com histórico vazio ainda (a persistência real de sessões executadas entra em outra fase), mas a tela abre normalmente em vez de recusar acesso.

- **Home não mostra mais "trial encerrado" pra quem acabou de começar**: o servidor agora indica explicitamente se o acesso está válido, e o banner de trial no topo da Home passa a refletir a realidade do usuário — apps com trial ativo veem "faltam X dias", quem passou vê a chamada pra assinar. Antes o campo esperado pelo app não vinha, e o banner sempre trocava para o estado bloqueado.

- **Título da aba "Av. Física" no app público estava como "Evolução"**: o cabeçalho da tela mostrava um nome que não combinava com a aba de baixo. Agora bate — "Avaliação Física" em ambos.

- **Botões flutuantes ("Nova avaliação" e "Novo treino") não quebram mais em telas menores**: em aparelhos com fonte grande, o texto estourava o botão. Ambos passaram a mostrar apenas o ícone de "+" com o texto disponível no toque longo (tooltip).

## AlfaMobi — 17/07/2026 — Atualização por produto: AlfaGym e AlfaControl não competem mais pelo mesmo canal

Esta versão resolve um problema arquitetural do auto-update: o AlfaMobi é um único aplicativo que atende dois produtos (AlfaGym para academias e AlfaControl para condomínios), mas até agora ambos compartilhavam o mesmo manifest de atualização — sempre que um lado publicava uma nova versão, o outro perdia acesso à sua própria atualização automática. Isso finalmente foi separado, e cada produto passa a receber as próprias atualizações sem interferir no ritmo do outro.

### Melhorias

- **Auto-update passa a diferenciar AlfaGym e AlfaControl automaticamente**: o aplicativo agora informa ao servidor qual produto está sendo usado pelo usuário logado, e recebe apenas as atualizações do canal correspondente. Um usuário logado como aluno de academia recebe as atualizações do AlfaGym; um usuário logado no condomínio recebe as do AlfaControl. Cada equipe publica no seu próprio ritmo sem risco de sobrescrever a versão do outro produto.

- **Compatibilidade com versões antigas do aplicativo**: aplicativos que ainda não foram atualizados para esta versão continuam funcionando como antes — o servidor responde com o canal padrão (AlfaGym) quando o produto não é informado. Assim a transição para o novo modelo é gradual, sem quebrar quem ainda não atualizou.

## AlfaMobi — 17/07/2026 — Ajustes finos por perfil, telas do UsuarioApp separadas, Editar perfil com foto/endereço e novos contatos da Alfa

Esta versão amarra um conjunto de acertos para diferenciar melhor o que o aluno de academia e o usuário do app público veem — cada um agora enxerga apenas o que faz sentido para o seu contexto — e ajusta pontos visuais que quebravam em aparelhos maiores ou em cenários específicos.

### Novidades

- **Home do aluno agora abre o menu de acesso rápido a Aulas e Perfil**: o ícone de três pontinhos (⋮) que dá entrada às telas de Aulas e Perfil, que já aparecia em Treino, Av. Física, Evolução e Aulas, agora também aparece na Home. Antes ficava faltando ali e o aluno tinha que voltar pra outra aba pra encontrar Perfil rapidamente.

- **UsuarioApp agora enxerga tela de Assinatura no lugar de Pagamentos/Meu Plano**: para quem usa o app sem estar vinculado a uma academia, as antigas telas de "Pagamentos" e "Meu plano" davam erro porque não fazem sentido nesse fluxo. Agora ambas abrem a nova tela de Assinatura do AlfaMobi, com R$ 9,90/mês, lista dos benefícios do plano premium (treinos, agenda pessoal, evolução física completa, bem-estar, sem propaganda), e as opções de pagamento por Pix e cartão. A integração real com o gateway de pagamento entra em breve — por enquanto as opções mostram um aviso "chega no próximo update".

- **UsuarioApp agora enxerga "Academias parceiras" no lugar de Presenças**: como o usuário do app não tem check-in numa academia específica, a antiga tela de "Minhas presenças" foi substituída por uma vitrine chamada "Academias parceiras" — que vai mostrar as academias que usam o AlfaGym e estão com o cadastro em dia. A vitrine em si ainda está aguardando a lista vir do servidor; enquanto isso, mostra um placeholder honesto do que virá.

- **Editar perfil ganhou foto e endereço**: a tela de Editar perfil agora tem, além do nome e e-mail, um avatar grande no topo com botão de trocar foto e um campo dedicado para endereço. Nome e e-mail continuam sendo salvos normalmente; foto e endereço aparecem visualmente e mostram um aviso "em breve" ao serem tocados, porque a persistência desses campos ainda depende de suporte adicional no servidor — o layout já fica pronto para o dia que o backend estiver disponível.

- **Menu de Configurações e Suporte agora mostra a academia do aluno**: no cabeçalho do menu que reúne Editar perfil, Alterar senha, Tema e outras opções, agora aparece a foto do aluno corretamente (antes ficava só nas iniciais em vários casos) e, embaixo do nome, o vínculo com a academia — "Sua academia" para quem tem vínculo e "Sem academia parceira" para quem usa o app sozinho. Isso deixa claro em qualquer momento o contexto do usuário logado.

### Melhorias

- **Botão de agendar nova aula deixou de quebrar o texto em telas estreitas**: o botão flutuante da agenda pessoal tinha "Agendar aula" escrito ao lado do sinal de +, e em telas com fonte grande ou aparelhos mais estreitos o texto começava a quebrar de forma feia. O botão passou a mostrar apenas o ícone + com "Agendar aula" como tooltip — mais limpo, funciona em qualquer tamanho.

- **Splash de abertura ganhou 1 segundo a mais**: mudança levada da versão 1.0.5 se junta a esta versão para quem estiver pulando updates — o splash agora dura 3 segundos em vez de 2, dando tempo do usuário ver a marca antes de cair no login.

- **Tela de Perfil não é mais cortada pelos botões de navegação do Android**: em aparelhos maiores como o Galaxy S25, o rodapé da tela de Perfil ficava atrás dos botões de navegação do sistema, escondendo o último item da lista. Foi aplicada uma área segura no rodapé para o conteúdo respeitar o espaço reservado à navegação do Android.

- **Contatos da Alfa atualizados no "Sobre o app"**: os telefones agora refletem os números atuais — WhatsApp (27) 4042-4157 e telefone (27) 3109-3265 — e o e-mail passou a ser comercial@solucoesgrupo.com. Cada linha continua sendo clicável e abrindo o aplicativo apropriado (WhatsApp, telefone, e-mail).

## AlfaMobi — 17/07/2026 — Cabeçalho consistente do aluno, Av. Física respeita permissão do professor, splash mais confortável

Esta versão amarra três acertos que reforçam consistência e clareza de papéis: o cabeçalho de identidade do aluno (foto + saudação + sino) passa a acompanhar todas as abas do AlfaGym, a Avaliação Física reconhece que o aluno vinculado à academia não é quem preenche a avaliação, e a splash de abertura ganha um segundo a mais para dar tempo do usuário ver a marca antes de já cair no login.

### Melhorias

- **Cabeçalho do aluno agora acompanha toda a experiência**: o topo com foto do aluno, saudação com o nome ("Boa tarde, Aluno Teste") e sino de notificações — que antes só existia na Home — agora aparece de forma consistente em Treino, Avaliação Física, Evolução e Aulas. Cada tela continua com seus botões próprios (histórico, comparar, recarregar, etc.), mas a identidade do usuário fica sempre à vista, reforçando que aquele espaço é dele.

- **Splash de abertura ganhou 1 segundo a mais**: o splash com a marca AlfaMobi vinha muito rápido — quase invisível — e ficava difícil de reconhecer que era o app carregando antes do login. A duração passou de 2s para 3s, o que dá tempo do usuário ver a marca sem tornar a abertura arrastada.

### Correções

- **Aluno da academia não vê mais botões para criar ou editar avaliação física**: essa é uma responsabilidade do professor, feita no painel web da academia. O aluno agora só consulta suas avaliações (ver evolução, comparar, recarregar), sem risco de acidentalmente criar um registro que polua o histórico oficial montado pelo professor. Usuários que estão no app sem vínculo com academia continuam podendo criar suas próprias avaliações normalmente — essa fase deles não mudou.

## AlfaMobi — 17/07/2026 — Atualização automática arruma instalação + tela "Sobre" com a Alfa por completo

Esta versão resolve dois pontos importantes: a atualização automática pelo próprio app no Android estava baixando o novo aplicativo mas não abria o instalador para de fato reinstalar, e a tela "Sobre" ainda mostrava só o nome e a versão sem qualquer contexto sobre quem faz o app.

### Correções

- **"Verificar atualização" agora reinstala o app até o fim**: no Android, ao aceitar uma atualização, o aplicativo baixava o novo pacote mas parava no visualizador de arquivos em vez de disparar o instalador do sistema. Faltavam as permissões que o Android exige para que um app instale outra versão de si mesmo. Agora o app declara essas permissões e, quando você toca em "Atualizar", o instalador nativo abre direto — basta confirmar para a nova versão substituir a antiga. Continua valendo a exigência única de habilitar "Instalar apps desconhecidos" para o AlfaMobi nas configurações do celular.

### Melhorias

- **Tela "Sobre o app" agora conta a história da Alfa**: em vez de mostrar apenas o nome do app e a versão, a tela ganhou um pitch curto sobre a Alfa Soluções Tecnológicas, uma lista dos três sistemas próprios em produção (AlfaGym, AlfaControl e AlfaHome) com toque para abrir o site de cada, e um bloco de contatos completo com WhatsApp, e-mail, site, Instagram, endereço em Vila Velha/ES e horário de atendimento — cada linha clicável abre o app apropriado (WhatsApp, mail, navegador ou mapas).

## AlfaMobi — 17/07/2026 — Redesign completo do aluno no AlfaGym: Av. Física premium, Home com academia, Treino/Evolução/Aulas renovados

Esta versão traz uma reformulação profunda da experiência do aluno da academia, com foco em três frentes: transformar a área de Avaliação Física num painel realmente premium com evolução visível de relance, reorganizar a Home para dar destaque à academia que o aluno frequenta em vez do treino do dia, e aplicar a mesma linguagem visual (cards com sombra suave, hierarquia clara, KPIs em destaque) nas abas de Treino, Evolução e Aulas.

### Novidades

- **Avaliação Física com dashboard premium por avaliação**: cada avaliação virou um card grande com três destaques em evidência — Peso, Gordura e Massa Magra — cada um mostrando a variação (▼/▲/=) em relação à avaliação anterior, com cor de "melhora" verde e de "piora" vermelha. As circunferências (cintura, quadril, braço, peitoral, coxa) agora aparecem como chips horizontais roláveis com seta indicando tendência. As fotos exibem sempre os 4 ângulos (frente, costas, laterais) — quando não há foto, o slot mostra um ícone de câmera. As observações do professor ganharam um card destacado próprio, e o cabeçalho identifica se é auto-avaliação do aluno ou avaliação registrada pelo professor.

- **Score de evolução com estrelas e resumo textual**: no topo da Av. Física agora há um card com 1 a 5 estrelas calculadas a partir dos indicadores concretos (perda de peso, redução de gordura, ganho de massa magra, redução de cintura) mais uma estrela de bônus por consistência (3+ avaliações). Abaixo, uma lista mostra o que o aluno já reduziu/ganhou desde a primeira avaliação, transformando números frios em vitórias palpáveis.

- **Fotos Antes/Depois com slider interativo**: o card de comparação visual agora tem um handle central que o aluno arrasta pra revelar a foto "depois" sobre a foto "antes" — igual apps de edição de fotos. Uma etiqueta discreta indica "ANTES" à esquerda e "DEPOIS" (em cor de destaque) à direita, com data e peso de cada momento embaixo. Torna a evolução física perceptível em segundos, sem precisar comparar números.

- **Linha do tempo vertical no histórico de avaliações**: os cards de avaliação agora ficam alinhados a uma linha do tempo vertical à esquerda, com um marcador colorido e a sigla do mês (Jan, Fev…) pra cada avaliação. Quando muda o ano, o número aparece em destaque acima do primeiro card daquele ano. Ajuda o aluno a entender que Av. Física é uma jornada, não uma pilha de registros isolados.

- **Tela "Ver Evolução" com gráficos por métrica**: novo botão na barra da Av. Física abre uma tela dedicada com um mini-gráfico pra cada métrica que tem dados suficientes — Peso, Gordura, Massa Magra, IMC, Cintura, Braço. Cada card mostra o valor atual em destaque, a variação total desde a primeira avaliação (colorida por "melhora") e a curva ao longo do tempo, incluindo pontos individuais.

- **Comparar avaliações lado a lado**: outro botão novo na Av. Física abre uma tela onde o aluno escolhe duas avaliações em dropdowns "ANTES/DEPOIS" e vê fotos comparativas mais uma tabela completa com todas as métricas (peso, IMC, gordura, massa magra, cintura, quadril, braço, peitoral, coxa) — cada linha traz o valor de cada momento e o delta calculado, colorido por sentido de melhora.

- **Home com "Minha academia" em vez de "Seu treino de hoje"**: a Home do aluno agora abre destacando a academia que ele frequenta — nome, endereço, logo e matrícula. Enquanto o backend não expõe esses dados (só o vínculo por ID), o card usa placeholders honestos até a academia disponibilizar as informações. O treino do dia continua acessível pela aba "Treino", que ficou muito mais rica.

- **Nova aba Evolução consolidada**: transformada em dashboard completo com 5 blocos — herói superior resumindo destaques ("perdeu 1,7 kg", "3 dias de sequência"), composição corporal com mini-gráfico de peso, treinos da semana com barra de progresso, sequência com melhor recorde e heatmap dos últimos 14 dias, e conquistas em forma de 4 badges (Primeiro passo, Consistente, Meta batida, Em chamas) que acendem à medida que o aluno alcança marcos reais.

- **Nav de baixo do aluno reorganizado**: agora são 4 abas fixas — Home, Treino, Av. Física, Evolução — em vez das 5 anteriores. Aulas e Perfil ficam disponíveis no menu suspenso (⋮) do canto superior direito de todas as telas do aluno, mantendo tudo a um toque de distância sem poluir a barra inferior.

### Melhorias

- **Treino do aluno com card "Sua semana" premium**: no topo da aba Treino apareceu um card com o número de treinos concluídos vs meta semanal, barra de progresso, badge "Meta batida" quando aplicável, e resumo do último treino (data, séries realizadas, quilos totais movimentados). Os cards de cada treino atribuído ganharam ícone em destaque, badge "ATUAL" no treino principal, chips com frequência e data de início, e sombra suave — visual muito mais premium que o antigo tile plano.

- **Aulas coletivas com resumo da semana e cards renovados**: acima da lista de aulas surgiu um card gradiente mostrando total de aulas nos próximos 7 dias, quantas o aluno já reservou, e destaque da próxima aula inscrita (nome + "hoje/amanhã às HH:mm"). Os cards de cada aula ganharam um box lateral em destaque com hora de início e fim, sombra suave, e borda colorida quando o aluno já está inscrito — muito mais fácil identificar as aulas em que já se comprometeu.

- **Saudação da Home usa nome + sobrenome**: em vez de mostrar só o primeiro nome (que quando o aluno se chama "Aluno Teste da Silva" virava só "Aluno"), a Home agora exibe os dois primeiros nomes ("Aluno Teste") — mais próximo de uma saudação real e evita confusão com placeholders genéricos.

- **Menu suspenso disponível em todas as abas do aluno gym**: o menu com "Aulas" e "Perfil" que fica ao lado do sino de notificações agora aparece em todas as telas do aluno (Home, Treino, Av. Física, Evolução, Aulas), garantindo acesso rápido e consistente independente de onde o aluno esteja no app.

### Correções

- **Fotos de exercícios do treino voltam a aparecer**: a URL pública das fotos de exercício estava sendo gerada apontando pro endereço interno do serviço de armazenamento em vez do domínio público da academia — o app baixava mas não conseguia carregar. A configuração foi corrigida no servidor e as fotos voltaram a exibir normalmente no detalhe de cada exercício.

- **Endpoints do aluno voltaram a responder após restauração de produção**: durante uma restauração para versão anterior, os endpoints que atendem o aluno no app (treinos, avaliações, evolução) tinham ficado sem o identificador do aluno no token, resultando em "endpoint não encontrado" nas abas. O token voltou a incluir o identificador e todas as áreas do aluno voltaram a funcionar.

## AlfaMobi — 04/05/2026 — Acessibilidade reforçada no Login e em Encomendas

Este release foi feito para corrigir problemas que apareciam justamente nos cenários mais sensíveis de uso no iPhone: teclado aberto, texto em negrito, fonte no tamanho máximo e telas com menos espaço útil. Antes, partes importantes do app continuavam funcionais em condições normais, mas quebravam visualmente quando o usuário ativava recursos de acessibilidade do sistema — surgiam overflows, textos cortados e componentes achatados. O foco desta entrega foi preservar o layout sem sacrificar legibilidade nem usabilidade.

### Melhorias

- **Tela de login agora se adapta melhor quando o teclado abre**: o formulário de acesso foi reorganizado para continuar centralizado quando há espaço, mas passar a rolar corretamente quando a altura da tela diminui. Antes, abrir o teclado podia causar estouro visual na tela de login, especialmente em iPhone com fonte ampliada. Agora o conteúdo se acomoda de forma mais previsível e o usuário consegue continuar o preenchimento sem elementos saindo da área visível.

- **Card de encomenda ficou resiliente a texto grande e negrito**: o título da encomenda, o status e as linhas auxiliares do card foram ajustados para suportar configurações agressivas de acessibilidade sem quebrar o layout. Antes, o nome da encomenda podia começar a quebrar ou empurrar outros elementos do cabeçalho; agora o card reorganiza melhor seus blocos e usa truncamento controlado quando necessário, mantendo a leitura clara sem deformar a interface.

- **Botões e ações da retirada ficaram mais robustos em acessibilidade alta**: elementos como “Confirmar retirada”, informações de assinatura e ações do card deixaram de depender de linhas horizontais rígidas. Antes, bastava combinar negrito com fonte máxima para alguns rótulos espremidos começarem a estourar ou empilhar de forma ruim; agora esses componentes encolhem com mais elegância ou quebram de forma controlada, preservando toque, leitura e contexto.

- **Barra de filtros de Encomendas ganhou altura responsiva**: os chips de status agora recebem mais altura conforme a escala de texto do sistema aumenta. Antes, com texto grande e negrito, os chips podiam parecer achatados na parte inferior porque a barra ficava comprimida por uma altura fixa. Agora a área do filtro cresce junto com a necessidade visual do conteúdo, o que deixa os chips com aparência correta e melhora o conforto de leitura.

### Correções

- **Correção de overflow recorrente na tela de login**: foi eliminado o estouro visual que aparecia quando o formulário precisava coexistir com o teclado e com menos altura útil disponível. O problema afetava principalmente usuários que usam ajustes de acessibilidade e deixava a primeira experiência do app visualmente quebrada logo na entrada.

- **Correção de distorções no fluxo de retirada de encomendas**: o painel de retirada e o rodapé dos cards foram ajustados para não dependerem de combinações rígidas de largura. Isso evita que mensagens de apoio, ações e botões pareçam comprimidos ou desalinhados em cenários de texto ampliado.

### Testes

- **Cobertura de widget para acessibilidade em Encomendas**: foi adicionada uma nova suíte de testes de widget validando a tela de encomendas com `boldText` ativo e escala de texto alta. Esses testes garantem que o título da encomenda, os botões de retirada e a barra de chips continuem estáveis em cenários que antes eram mais propensos a regressões visuais.

---

## AlfaMobi — 04/05/2026 — FABs circulares + saudação personalizada na Home

### Melhorias

- **Botões de ação (FABs) padronizados em todo o app — ícone circular, sem texto**: todos os 19 botões flutuantes de adicionar que exibiam um label textual ("Nova pessoa", "Novo aluno", "Nova matrícula" etc.) foram convertidos para o padrão circular com ícone apenas. Antes, o módulo SaaS já usava FABs circulares enquanto Gym, Cadastros e SaaS Gym usavam o formato `Extended` com texto; isso criava uma inconsistência visual clara entre módulos do mesmo app. A mudança libera espaço nas listas — especialmente em telas com muitos itens — e segue a convenção consolidada em apps móveis modernos, onde um botão circular com `+` é imediatamente reconhecido como "adicionar". O texto dos labels foi preservado como `tooltip` para manter a acessibilidade: leitores de tela anunciam a ação e no Android um toque longo exibe o label em um balão. O tema global também foi ajustado (`CircleBorder()`) para garantir forma circular uniforme em qualquer FAB que seja adicionado no futuro sem precisar declarar o shape individualmente.

- **Saudação personalizada na Home substitui o nome do produto**: a AppBar da tela inicial exibia estaticamente "AlfaControl" ou "AlfaGym" dependendo do produto — uma informação redundante (o usuário sabe qual app está usando) que ocupava espaço sem agregar nada. Agora exibe uma saudação baseada no horário: "Bom dia, [Primeiro nome]" (antes das 12h), "Boa tarde, [Primeiro nome]" (12h–18h) ou "Boa noite, [Primeiro nome]" (após 18h). O nome vem diretamente dos dados de login já disponíveis no app — não há nenhuma requisição adicional. O texto usa um tamanho ligeiramente menor (17px/médio) em vez do padrão da AppBar (22px/semibold) para não competir visualmente com o conteúdo da página, que começa logo abaixo com os cards de resumo do dia.

---

## AlfaMobi — 04/05/2026 — Encomendas: auditoria de segurança e hardening completo

Este release é resultado de uma revisão sistemática e profunda do módulo de encomendas — cada ponto de falha foi mapeado, avaliado e corrigido antes de avançar com novas funcionalidades. O objetivo foi fechar brechas que existiam silenciosamente e que só aparecem em produção: fotos que não carregam quando o servidor exige autenticação, crashes que derrubam a lista inteira por uma data mal formatada, duplicatas que passam sem aviso, corridas entre notificações push e ações do usuário. Nada aqui é cosmético.

### Segurança

- **Fotos de encomenda agora são carregadas com autenticação**: antes, as imagens dos pacotes eram exibidas via `Image.network` puro — sem o cabeçalho `Authorization`. Isso causava dois problemas graves: (1) se o backend exige JWT para servir a imagem (como deveria), ela simplesmente não carregava, aparecendo um ícone de erro; (2) se a URL fosse pública, qualquer pessoa com o link poderia ver a foto do pacote sem nenhum controle de acesso. Agora todas as requisições de imagem incluem o token JWT do usuário logado via `NetworkImage(url, headers: {'Authorization': 'Bearer $token'})`, exatamente como as demais chamadas de API.

- **Limite de 3 MB aplicado antes de codificar a foto em base64**: o app redimensiona a imagem para 1280×1280 com qualidade 75%, mas isso não garante o tamanho final — uma foto PNG com áreas transparentes ou uma HEIC do iOS pode resultar em 5–10 MB após o redimensionamento, e o base64 adiciona mais 33% de overhead. Antes dessa correção, enviar uma foto grande causava timeout ou estouro de memória silencioso: a requisição ia, o servidor recusava, e o usuário via uma mensagem genérica de erro. Agora o app verifica o tamanho dos bytes *antes* de codificar e exibe uma mensagem clara — "Imagem muito grande. Use uma foto menor (máx. 3 MB)." — sem chegar a tentar o envio.

### Correções

- **Crash silencioso no parse de data**: o campo `recebidaEm` era parseado com `DateTime.parse(j['recebidaEm'].toString())` — que lança `FormatException` se o campo vier `null` do backend, ou se o formato não for ISO 8601 puro. Um único registro malformado na página derrubava o parse de *todos* os itens, resultando em lista vazia sem mensagem de erro clara. Corrigido com `DateTime.tryParse` com fallback para `DateTime.now()`, de forma que registros bem formados continuam carregando normalmente mesmo que um item da página esteja inconsistente.

- **Crash ao comparar `avisoDeduplicata`**: o campo era obtido com `j['avisoDeduplicata'] as bool?` — um cast direto que lança `TypeError` se o backend retornar `0`, `1` ou qualquer valor não-booleano (comportamento documentado em alguns cenários de serialização Java). Corrigido para `j['avisoDeduplicata'] == true`, que é seguro para qualquer tipo de entrada.

- **Race condition entre notificação push e operação em andamento**: quando o usuário estava com o painel de cancelamento aberto e chegava uma notificação de nova encomenda, o serviço de push disparava `carregar(refresh: true)`, que limpava a lista e recarregava do zero. A encomenda que estava sendo cancelada podia mudar de posição ou status por baixo, causando inconsistência visual ou falha silenciosa na operação. Corrigido com uma flag `_mutando` no provider: enquanto qualquer mutação (registrar, cancelar, marcar retirada) estiver em andamento, o `carregar` retorna imediatamente sem alterar o estado, garantindo que a operação corrente termine de forma coerente.

- **Banner de encomendas antigas não resetava corretamente após falha de rede**: o contador de encomendas paradas (`antigasCount`) era inicializado com `0`, o que fazia o banner de alerta desaparecer silenciosamente quando o endpoint `/api/encomendas/resumo` falhava — como se não houvesse encomendas antigas, quando na verdade o dado não havia sido carregado. Corrigido: o valor inicial agora é `-1` (sentinel explícito de "nunca carregado"), e em caso de falha o valor anterior é mantido. O banner só desaparece quando o servidor confirma que não há encomendas antigas — nunca por falha de rede.

- **Mensagens de erro de rede sem distinção de causa**: erros 403 (sem permissão), 404 (não encontrado), 409 (conflito de concorrência) e 500 (erro interno) retornavam todos a mesma mensagem genérica ao usuário, tornando impossível entender o que havia ocorrido. Corrigido usando o utilitário `humanizeDio` já existente no projeto — que extrai mensagens do corpo da resposta, trata 401 (sessão expirada), 403 (sem permissão), 409 (conflito de atualização) e 500+ com mensagens distintas — eliminando também a duplicação de código.

### Novidades

- **Confirmação antes de registrar duplicata**: quando o operador tenta registrar uma encomenda para uma pessoa que já tem outra encomenda pendente, um diálogo de confirmação aparece *antes* de qualquer chamada ao servidor — "Fulano já tem uma encomenda aguardando retirada. Registrar mesmo assim?" — com as opções de confirmar ou cancelar. Antes, o registro era feito sem aviso e o servidor sinalizava a duplicata apenas após o fato, via um SnackBar que muitas vezes passava despercebido.

- **Filtro "Canceladas" na lista de encomendas**: gestores e administradores agora têm um chip adicional "Canceladas" na barra de filtros da tela de encomendas, permitindo auditar todos os registros cancelados com seus motivos de forma isolada. O chip só aparece para perfis com permissão de cancelar (`canCancelarEncomenda`) — porteiros, recepcionistas e operadores continuam vendo apenas "Todos / Pendentes / Retiradas".

- **Gate explícito para confirmar retirada**: a ação de marcar retirada de encomenda agora passa pelo campo `canMarcarRetiradaEncomenda` na matriz de permissões, em vez de depender do tipo genérico de sessão. O comportamento atual é idêntico ao anterior — todos os perfis operacionais podem confirmar retirada — mas o campo agora existe como ponto de configuração explícito para restringir por perfil no futuro (ex.: "só recepcionista confirma retirada, porteiro apenas registra chegada") sem refatoração da tela.

### Testes

Foram criados dois novos conjuntos de testes para o módulo de encomendas, que até então não possuía cobertura alguma:

- **`test/features/encomendas/models/encomenda_test.dart`** — 13 testes cobrindo: parse completo de payload, `recebidaEm` nulo e malformado (os dois bugs de crash corrigidos acima), `avisoDeduplicata` com `bool`, `int` e `null`, campos opcionais ausentes, `id` como `num`, todos os getters de status (`aguardando`, `retirada`, `cancelada`) e `copyWith` preservando campos não alterados.

- **`test/features/encomendas/state/encomendas_provider_test.dart`** — 8 testes cobrindo: estado inicial completo (incluindo `antigasCount = -1`), `limpar()` resetando todos os campos, guard de no-op no `setFiltroStatus`, e invariantes síncronos do provider.

- **`test/features/auth/perfil_condo_permissions_test.dart`** — adicionado teste para `canMarcarRetiradaEncomenda`, cobrindo todos os perfis operacionais (`true`) e `null` (`false`).

---

## AlfaMobi — 30/04/2026 — Diferenciação de perfis: operador vs recepcionista

### Correções

- **Operador não pode mais editar pessoas**: o perfil "operador" consultava e editava pessoas igual ao recepcionista. Agora o operador apenas consulta — quem cadastra e atualiza dados é o recepcionista.

---

## AlfaMobi — 30/04/2026 — Correção de permissões do recepcionista

### Correções

- **Recepcionista não vê mais Tipos de Pessoa**: o tile "Tipos de Pessoa" ficava visível para recepcionistas e operadores, mas essa seção é exclusiva do gestor do sistema. Corrigido.
- **Recepcionista não vê mais Veículos**: o tile "Veículos (Em breve)" também aparecia indevidamente para recepcionistas e operadores. Corrigido — o item só aparece para gestores.

---

## AlfaMobi — 30/04/2026 — Novo ícone e correção de cores

### Melhorias

- **Novo ícone do app**: ícone atualizado em todas as densidades para Android e iOS.
- **Correção de cores nos botões e badges**: botões de ação (FAB) e alguns elementos visuais apareciam em lilás — cor padrão do sistema de design do Android/iOS — em vez da cor vermelha do AlfaControl e laranja do AlfaGym. Corrigido em todo o app.

---

## AlfaMobi — 30/04/2026 — Encomendas: foto somente pela câmera

### Segurança

- **Foto do pacote somente pela câmera**: removida a opção de escolher imagem da galeria no registro de encomendas. A galeria permitia enviar uma foto antiga, de outro pacote ou baixada da internet — sem nenhuma garantia de que representava o pacote físico presente no momento do registro. Com câmera obrigatória, a foto é sempre capturada em tempo real, fechando essa brecha de fraude.

---

## AlfaMobi — 30/04/2026 — Módulo de Encomendas: foto, cancelamento com motivo e proteções de segurança

### Novidades

- **Foto do pacote no registro**: ao registrar uma encomenda, o porteiro ou recepcionista pode adicionar uma foto do pacote diretamente pelo app — usando a câmera do celular ou escolhendo uma imagem da galeria. A foto fica armazenada com segurança e é exibida no card da encomenda para qualquer usuário autorizado que consultar o registro.

- **Cancelamento com motivo obrigatório**: gestores e administradores agora podem cancelar uma encomenda registrada, mas apenas informando o motivo. Ao tocar em "Cancelar encomenda", um painel deslizante apresenta quatro opções predefinidas — _Registrado por engano_, _Pacote devolvido ao remetente_, _Duplicata de outra encomenda_ e _Outro_ — sendo que a opção "Outro" exige uma descrição livre de até 200 caracteres. Isso cria um rastro claro para auditoria e evita cancelamentos sem justificativa.

- **Quem registrou, retirou e cancelou aparece no card**: cada encomenda agora exibe o nome do usuário responsável por cada ação — "Registrado por: [nome]", "Retirado por: [nome]", "Cancelado por: [nome] — Motivo: [texto]". Essa informação é visível tanto para operacionais quanto para o próprio destinatário da encomenda, eliminando disputas do tipo "minha palavra contra a sua" em caso de questionamentos.

- **Notificações de ciclo completo**: o destinatário da encomenda recebe notificação push em cada transição de status — não apenas na chegada, mas também quando a encomenda for retirada ou cancelada. O push de cancelamento inclui o motivo informado pelo gestor.

- **Alerta de encomendas paradas**: quando há encomendas aguardando retirada há mais de 7 dias, um banner laranja aparece no topo da lista operacional indicando a quantidade. Isso facilita a abordagem proativa ao morador ou responsável.

- **Dialog de retirada com mais informações**: ao confirmar que uma encomenda foi retirada, o dialog agora exibe a descrição completa do pacote, o remetente e o nome do destinatário — reduzindo o risco de confirmar a retirada do item errado durante o pico de movimento na portaria.

- **Unidade/matrícula no autocomplete de pessoas**: durante o registro de encomenda, os resultados da busca por nome agora exibem também a matrícula ou número de unidade da pessoa, facilitando a distinção entre cadastros com nomes similares (ex.: dois moradores com o mesmo sobrenome).

- **Aviso de encomenda duplicada**: se já existir uma encomenda pendente do mesmo remetente para a mesma pessoa nas últimas 6 horas, o app exibe um aviso em laranja logo após salvar. O registro não é bloqueado — apenas alertado — para cobrir o caso legítimo de dois pacotes do mesmo fornecedor chegando no mesmo dia.

### Segurança

- **Cancelamento restrito a gestores**: porteiros, recepcionistas e operadores podem registrar e confirmar retiradas, mas **não podem cancelar** encomendas. O botão de cancelamento é exibido apenas para gestor do cliente e administradores. Essa restrição também é reforçada no backend — uma tentativa de cancelamento por perfil não autorizado resulta em HTTP 403.

- **Proteção contra corrida de requisições**: se dois usuários tentarem marcar a mesma encomenda como retirada ou cancelada simultaneamente (por exemplo, dois porteiros abrindo o app ao mesmo tempo), apenas o primeiro é aceito. O segundo recebe uma mensagem de erro indicando que o status já foi alterado. Isso evita registros duplicados ou estados inconsistentes.

- **Limite de tamanho de foto**: fotos enviadas pelo app têm tamanho máximo de aproximadamente 1,5 MB em formato base64 validado pelo backend, prevenindo o envio acidental de imagens muito pesadas.

- **Mensagens de erro padronizadas**: erros de estado inválido (como tentar cancelar uma encomenda já retirada) retornam uma mensagem genérica para o cliente, sem vazar detalhes internos do sistema.

### Correções

- **Botão "Cancelar" invisível para porteiro/recepcionista/operador**: o controle visual agora segue a matriz de permissões (`canCancelarEncomenda`) em vez de uma verificação genérica de sessão — elimina a possibilidade de um perfil desconhecido enxergar o botão indevidamente.

- **Bug no registro com remetente preenchido**: uma query JPQL mal formada (`COUNT > 0` direto no SELECT) causava erro 500 em qualquer registro que incluísse o nome do remetente. Corrigido para `CASE WHEN COUNT > 0 THEN true ELSE false END`.

- **Nome "Registrado por" desaparecia após retirada ou cancelamento**: ao marcar como retirada ou cancelada, a resposta do backend voltava sem o campo `registradoPorNome`, fazendo a linha desaparecer do card até o próximo refresh manual. Corrigido para sempre incluir o nome de quem registrou na resposta.

- **Tela de registro podia travar em dispositivos lentos**: se o usuário navegasse para fora da tela enquanto o app ainda estava processando a foto selecionada (câmera ou galeria), o widget já descartado tentava atualizar o estado e causava um erro silencioso. Adicionado guarda de ciclo de vida.

- **Controlador de texto não era liberado**: o campo livre de motivo de cancelamento criava um controlador de texto que nunca era descartado após fechar o painel, acumulando recursos em sessões longas. Corrigido.

- **Erros silenciosos no provider**: falhas de rede e erros HTTP nos métodos de registro, cancelamento e retirada eram descartados sem nenhum registro. Agora os erros são logados no console de desenvolvimento para facilitar diagnósticos.

- **Typo no nome interno de componente**: `_EncomentasPendentesCard` (faltava o 'd') corrigido para `_EncomendasPendentesCard`.

- **Filtro de status ignorado para o morador**: ao consultar as próprias encomendas passando o parâmetro `status`, o filtro era silenciosamente ignorado e todas as encomendas eram retornadas independente do status solicitado. Corrigido no backend.

### Melhorias técnicas

- **Testes de unidade expandidos**: 27 testes novos e existentes cobrem os caminhos críticos — happy path de registro/retirada/cancelamento, corrida de requisições, detecção de duplicata, bloqueios por usuário inativo/senha provisória/sem e-mail no dispatcher de push, e todos os perfis operacionais nos gates de permissão de encomendas.

---

## AlfaMobi — 30/04/2026 — Ajustes de permissão no perfil Porteiro

### Correções

- **Tipos de Pessoa não aparece mais para o Porteiro**: o tile de Tipos de Pessoa no hub de Cadastros era exibido para qualquer perfil com permissão de consulta de Pessoas — incluindo Porteiro. Como Tipos de Pessoa é uma configuração administrativa, agora só aparece para perfis com permissão de edição (gestores).
- **Acesso rápido do Porteiro corrigido**: os tiles "Onde posso acessar" e "Horários" apareciam incorretamente na home do Porteiro. "Onde posso acessar" é uma funcionalidade voltada para a Pessoa (morador/cliente), não para o operacional; "Horários" está fora do escopo de permissão do Porteiro. Ambos foram removidos do acesso rápido para esse perfil.

---

## AlfaMobi — 29/04/2026 — Novo ícone do app

### Melhorias

- Novo ícone do AlfaMobi: fundo teal com gradiente e as letras **αm** em branco, identidade visual mais limpa e moderna.

---

## AlfaMobi — 29/04/2026 — Módulo Financeiro no hub do gestor

### Novidades

- **Módulo Financeiro no Cadastros**: gestores do cliente agora encontram uma nova seção "Financeiro" no hub de Cadastros com os tiles **Cobranças**, **Inadimplência** e **Relatórios Financeiros**. Os tiles aparecem marcados como "Em breve" enquanto as telas estão em desenvolvimento.
- A seção só aparece quando **duas condições** forem verdadeiras ao mesmo tempo: (1) o perfil do usuário tem acesso a dados financeiros (gestor\_cliente e administradores — porteiro, recepcionista e operador não têm acesso a informações financeiras do condomínio) e (2) o **módulo Financeiro está ativo no plano contratado** pelo cliente no painel SaaS. Clientes sem o módulo contratado não veem a seção — a tela de Cadastros permanece igual à de antes para eles.

### Melhorias

- O app agora consulta automaticamente os módulos contratados pelo cliente (`/api/me/modulos`) ao fazer login e ao retomar a sessão, mantendo o estado de módulos sempre sincronizado com o que está ativo no painel SaaS.

---

## AlfaMobi — 29/04/2026 — Correção: status online dos dispositivos

### Correções

- **Dispositivos sempre apareciam como "Offline"** mesmo quando o equipamento estava conectado e respondendo. A causa era um mapeamento incorreto dos campos retornados pelo servidor (`statusOnline` e `ultimoPing`) — o app lia nomes antigos que não existiam mais na resposta, fazendo com que todos os dispositivos caíssem no estado padrão "Offline". Corrigido o mapeamento; agora o badge Online/Offline reflete o estado real do equipamento.

---

## AlfaMobi — 29/04/2026 — Fonte Inter

### Melhorias

- O app adotou a **fonte Inter** em todas as telas — a mesma usada por Linear, Stripe e Vercel. A mudança melhora a legibilidade em listas, dashboards e chips, especialmente em textos pequenos e números de KPIs.

---

## AlfaMobi — 29/04/2026 — Empresas, Vínculos em massa e Permissões extras de usuário

### Novidades

- **Empresas**: o gestor do cliente gerencia as empresas/organizações vinculadas ao tenant direto pelo app — criar, editar (nome, CNPJ, observação, empresa padrão, ativo/inativo) e excluir. Operacionais (porteiro, recepcionista, operador) veem a lista em modo leitura. Tile na seção Gestão de Cadastros.
- **Vínculos em massa**: nova tela que permite filtrar pessoas por nome, empresa ou tipo, selecionar múltiplas (ou todas as páginas de uma vez) e aplicar um vínculo em lote — vincular a uma empresa, a um perfil de acesso ou criar uma regra direta de dispositivo + horário (com tipo Permitir/Negar). Restrito a gestores e administradores. Tile na seção Gestão de Cadastros.
- **Permissões extras por usuário**: ao acessar um usuário operacional pelo menu de Usuários, o gestor agora pode conceder permissões granulares além do que o perfil já inclui por padrão — como Gerenciar Horários, Gerenciar Usuários, Ver Auditoria, entre outras. Permissões incluídas no perfil aparecem como chips fixos (não editáveis); as adicionais como checkboxes.

### Melhorias

- **Hub de Cadastros reformulado**: a tela Cadastros migrou do layout em grade para lista estilo iOS, igual ao Menu — seções GESTÃO / CONTROLE DE ACESSO / ADMINISTRAÇÃO com cards arredondados, ícone e seta, muito mais legível e navegável em qualquer tamanho de tela.
- O tile **Veículos** (em breve) agora só aparece para perfis que já têm acesso a Gestão, evitando confusão para perfis sem permissão.

### Correções

- Formulário de empresa: uma exceção inesperada durante o salvamento não travava mais o botão "Salvar" indefinidamente — `_saving` sempre é resetado via `finally`.
- Tela de Vínculos: loop infinito de carregamento corrigido — qualquer falha de rede ou resposta inesperada agora exibe mensagem de erro em vez de manter o spinner para sempre.

---

## AlfaMobi — 28/04/2026 — Tipos de Pessoa no app

### Novidades

- O **gestor do cliente** agora gerencia os **tipos de pessoa** (morador, dependente, visitante etc.) direto pelo app — antes, esse catálogo só existia no sistema web. O tile aparece na seção Gestão da aba Cadastros, ao lado de Pessoas, Veículos e Dispositivos.
- A tela permite **criar, editar e desativar** tipos. Pessoas já cadastradas com um tipo desativado **não são afetadas** — o tipo só deixa de aparecer no select de novas pessoas.
- Operacionais (porteiro, recepcionista, operador) **enxergam o catálogo** (precisam pra preencher o tipo de novas pessoas), mas **não podem editar**.

---

## AlfaMobi — 28/04/2026 — Gestor do cliente: Usuários, Auditoria e Backup no app

### Novidades

- O **gestor do cliente** (perfil `gestor_cliente`) agora acessa pelo app **3 telas que existiam só no sistema web**: **Usuários**, **Auditoria** e **Backup**. Antes, esses tiles ficavam restritos ao painel SaaS (super admin / admin de revenda) e o gestor precisava abrir o web para gerenciar a equipe, conferir trilhas de auditoria ou disparar/restaurar backup do próprio condomínio.
- Os tiles aparecem em uma nova seção **"Administração"** dentro da aba **Cadastros**, junto com Gestão e Controle de Acesso. Operacionais (porteiro, recepcionista, operador) continuam sem acesso — segurança preservada.

---

## AlfaMobi — 28/04/2026 — Layout adaptativo para tablet

### Novidades

- O AlfaMobi agora se adapta ao tamanho da tela. Em **tablet** (iPad ou Android tablet), o app ganha um menu lateral fixo (no lugar da barra inferior do celular), e as principais telas usam toda a largura disponível em vez de esticar uma única coluna.
- **Hubs** (Cadastros, Operação, SaaS, Meu painel do aluno) mostram **3 ou 4 tiles por linha** no tablet, em vez de 2.
- **Listas** (Alunos, Pessoas, Tenants, Despesas, Recebíveis, Logs de Acesso, Notificações, Avisos, Planos, Equipe, Usuários, Clientes, Revendas e outras) ficam em **grade de 2 colunas** no tablet em pé e **3 colunas** no tablet deitado.
- **Formulários** (cadastro de aluno, pessoa, plano, despesa, equipe, revenda, aviso, matrícula, cliente, usuário) ficam **centralizados com largura controlada** no tablet — antes, os campos de texto se esticavam pela tela inteira.
- **Dashboards e relatórios** (Resumo do AlfaGym, Financeiro, Acessos, Caixa) mostram **dois cards lado a lado** quando há largura suficiente — Base de alunos + Financeiro, Receita + Despesa, Top alunos + Top funcionários, etc.

### Melhorias

- No celular, **nada muda visualmente** — o layout antigo de uma coluna foi preservado para garantir que a experiência mobile continue idêntica.
- KPIs dos relatórios (Caixa, Contratos, Produtos, Comissões) crescem de **2 colunas no celular** para **3-4 colunas no tablet**, ocupando melhor o espaço.

---

## AlfaMobi — 27/04/2026 — Push de notificação no AlfaGym

### Novidades

- O **AlfaGym** agora registra o aparelho do usuário no servidor pra receber notificações push (mesma estrutura que já existia no AlfaControl). Antes, o app tentava registrar e levava 404 — push pra qualquer perfil do AlfaGym (admin, aluno, recepcionista) ficava impossível. Agora a estrutura está pronta para notificações futuras (presença registrada, fatura próxima do vencimento etc.).

---

## AlfaMobi — 27/04/2026 — Acessibilidade + correções visuais

### Melhorias

- O app agora **respeita as configurações de acessibilidade do iOS** (Tamanho do Texto, Texto Maior e Texto em Negrito). Antes, no aparelho real, telas estouravam ou cortavam textos quando essas configurações estavam ligadas. Agora os botões e cards crescem em altura conforme o texto cresce, sem cortar nada.
- **Tela de login** redesenhada na fase de escolha do sistema: o conteúdo centraliza quando cabe e rola quando não cabe — sem mais aviso de "overflow" no rodapé.
- **Botões de tema** (Sistema/Claro/Escuro) no Menu, **filtros de status** na lista de Equipe e **cards de KPI** no Dashboard SaaS foram corrigidos para acomodar texto em negrito + tamanho grande sem cortar palavras.

### Para revisores

- Disponibilizado o `docs/REVIEW_GUIDE.md` na raiz do app — manual completo cobrindo arquitetura de sessões, matriz de permissões por perfil, checklist de teste tela-a-tela e cenários negativos.

---

## AlfaMobi — 26/04/2026 — Super_admin entra no painel do cliente pelo app

### Novidades

- **Super_admin pode entrar no painel de qualquer cliente direto pelo app** — botão "Entrar como cliente/academia" no detalhe de cada Cliente (AlfaControl) ou Tenant (AlfaGym). Abre o painel operacional com os mesmos dados que o gestor enxerga, sem precisar abrir o navegador. Mesmo comportamento do "▶ Entrar" do painel SaaS web.
- **Banner no topo da tela** avisa quando você está vendo como cliente/academia, com botão "Sair" pra voltar ao painel SaaS — não tem como esquecer que está em modo impersonação.

### Segurança

- A volta ao painel SaaS revalida o perfil no servidor — se o usuário for rebaixado de super_admin durante a sessão, perde o privilégio na hora.
- Cada entrada e saída de painel impersonado ficam **registradas em auditoria** (mesma trilha do "Trocar Cliente" do web).

---

## AlfaMobi — 26/04/2026 — Painel SaaS do AlfaControl com visual do AlfaGym

### Melhorias

- O **painel SaaS do AlfaControl** (Carteira / Operação) ganha o mesmo visual do painel SaaS do AlfaGym: tiles em lista com ícone redondo colorido, descrição embaixo do nome e seta à direita — antes eram cartões quadrados em grade 2x2 sem descrição. Agrupamento e tiles disponíveis continuam iguais.

---

## AlfaMobi — 26/04/2026 — Senha provisória do aluno + endurecimento (Fase D4)

### Novidades

- **Aluno troca a senha no primeiro acesso.** Quando a recepção define a senha pra liberar o login, o app passa a pedir a troca antes de mostrar qualquer dado pessoal. Botão de cadeado no canto da tela do aluno permite trocar de novo a qualquer momento.

### Segurança

- O **acesso ao painel do aluno fica bloqueado até a troca da senha provisória** — antes o aluno conseguia usar o app inteiro sem trocar.
- E-mail duplicado em cadastro de aluno passa a mostrar **"Já existe um usuário com este e-mail"** (era erro genérico em corrida com o cadastro do AlfaControl).
- Login do app rejeita servidor sem chave de assinatura forte configurada — evita que um deploy mal-configurado deixe sessões vulneráveis.

### Melhorias

- 23 novos testes de auditoria fecham as lacunas de cobertura no fluxo do aluno (token, autenticação, multi-tenant, LGPD).

---

## AlfaMobi — 26/04/2026 — Endurecimento do app do aluno (Fase D3)

### Correções

- **Histórico de presenças** voltou a contar corretamente os check-ins feitos no fim da noite. Antes, qualquer presença registrada entre 21h e 23h59 podia desaparecer do filtro do dia (era atribuída ao dia seguinte por causa do fuso). Agora o cálculo usa o horário local da academia.
- **"Meu plano"** mostra a tela de "sem contrato" no formato correto quando o aluno ainda não tem contrato cadastrado. Antes podia mostrar erro genérico em algumas situações.
- Erros de autenticação no app do aluno mostram **mensagem clara em vez de "Erro 500"** quando o token está expirado, o aluno foi inativado ou pertence a outra academia.

### Melhorias

- **Aluno inativado/excluído perde acesso ao app imediatamente** — antes a sessão sobrevivia até o token expirar (até 1h depois).
- **Token do aluno valida a academia** — se o aluno for movido entre academias depois do login, a sessão antiga não vê dados da academia errada.
- **Senha de acesso do aluno** passa a exigir **mínimo de 8 caracteres** (era 6) tanto na criação quanto na redefinição.
- **Exclusão de conta (LGPD)** agora desliga o flag de acesso ao app do aluno e desconecta o registro de usuário, evitando estado inconsistente.

### Segurança

- 13 novos testes de auditoria cobrem a geração e validação do token do aluno e o controle de acesso de todos os endpoints `/me/*`.

---

## AlfaMobi — 26/04/2026 — Tile "Meu treino" volta para "Em breve"

### Correções

- O tile **"Meu treino"** dentro do painel do aluno volta a aparecer como **"Em breve"**. O módulo de Treinos do AlfaGym ainda está em reformulação e não deve ser oferecido — alinha o painel do aluno com o tile **Treinos** do painel do funcionário, que já estava nesse estado. As demais seções do painel do aluno (Pagamentos, Presenças, Meu plano) continuam funcionais.

---

## AlfaMobi — 26/04/2026 — Acesso do aluno ao app AlfaGym (Bloco D)

Aluno passa a logar no AlfaMobi com painel próprio. Antes só funcionários da academia (admin / gerente / recepcionista / professor) tinham acesso; agora o aluno vê só dados dele.

### Novidades

- O **aluno faz login** com e-mail e senha definidos pela recepção. No cadastro do aluno (web/app), basta marcar **"Tem login no sistema"** e definir uma senha — a partir daí o aluno entra no app dele.
- Tela inicial do aluno mostra um **resumo rápido**: presenças no mês corrente, próximo vencimento (com cor laranja/vermelho quando próximo ou atrasado) e tiles pra abrir cada seção.
- **Meu treino** — lista os treinos atribuídos pelo professor com nome, descrição, data de início e frequência.
- **Pagamentos** — banner com total em aberto, lista de **faturas pendentes** ordenadas por vencimento (com aviso "Vencida há X dias" / "Vence hoje" / "Vence em N dias") e toggle pra mostrar/ocultar **faturas pagas**.
- **Presenças** — timeline dos check-ins do aluno, com seletor de período no canto superior direito (default últimos 30 dias).
- **Meu plano** — card de status (verde / laranja / vermelho conforme dias até o vencimento) + dados do contrato (plano, valor, valor com desconto, dia de vencimento, forma de pagamento, datas de início e fim).

### Melhorias

- Login do aluno **não exige seleção de unidade** — vai direto pro painel após informar e-mail e senha.
- Aluno **só vê dados próprios** em todas as telas (gates de segurança no backend mais defesa em camadas no app).
- CPF do aluno **não trafega** para o app (proteção de dado sensível segundo a LGPD).
- Pull-to-refresh em todas as telas; ao trocar de academia/unidade, dados zeram.

---

## AlfaMobi — 26/04/2026 — Pagamentos: histórico e estorno por aluno (Fase C4.3)

Fecha o bloco C4 — Caixa, Despesas e Pagamentos.

### Novidades

- O perfil do aluno ganha botão **"Pagamentos"** no canto superior direito que abre uma tela com **histórico completo** de pagamentos do aluno em todas as cobranças.
- Cada pagamento mostra **método** (PIX, Crédito etc.), **valor**, **data**, **número da cobrança** e **observações**. Pagamentos parcelados aparecem com o número de parcelas.
- **Total pago** somando o histórico (pagamentos estornados não entram na conta).
- **Estornar pagamento** com diálogo de confirmação que **exige motivo**. Pagamentos estornados ficam visíveis na lista com etiqueta "Estornado", valor riscado e ícone diferente, e geram saída automática no caixa.

### Melhorias

- Pull-to-refresh recarrega o histórico.
- Trocar de aluno reseta a lista automaticamente; trocar de academia/unidade zera tudo.

---

## AlfaMobi — 26/04/2026 — Despesas: CRUD, pagamento e cancelamento (Fase C4.2)

### Novidades

- Novo tile **Despesas** no painel da academia (admin / gerente / recepcionista) com **lista filtrável** (Todos / Pendente / Pago / Cancelado), busca por descrição ou fornecedor, e **total pendente** somado no rodapé do filtro atual.
- Cada despesa mostra **avatar com ícone da categoria** (Aluguel, Salários, Energia, Água, Manutenção, Marketing, Equipamentos, Impostos, Outros), **badge de status** (Pendente / Pago / Cancelado) e um **subtítulo inteligente**: "Vencida há X dias", "Vence hoje", "Vence em N dias" ou "Pago em DD/MM".
- **Botão de ação** em cada despesa pendente: **Marcar como paga** abre um diálogo pra escolher a forma de pagamento (Dinheiro / PIX / Crédito / Débito / Boleto / Transferência); ao confirmar, a despesa entra automaticamente como saída no caixa do dia.
- **Editar despesa** com formulário em 5 seções: Identificação (descrição/valor/fornecedor), Categoria e Tipo (Fixa/Variável), Vencimento+Pagamento+Forma+Status, Recorrência (Mensal/Trimestral/Semestral/Anual) com total de parcelas, e Observações.
- **Cancelar despesa** com confirmação. Despesas pagas não podem ser canceladas.
- **FAB "Nova despesa"** abre o mesmo formulário em branco.

### Melhorias

- Pull-to-refresh recarrega a lista.
- Busca usa atraso de 300 ms pra não disparar chamada a cada tecla.
- Dados zeram ao trocar de academia/unidade.

---

## AlfaMobi — 26/04/2026 — Caixa diário do operador (Fase C4.1)

### Novidades

- Novo tile **Caixa** no painel da academia (admin / gerente / recepcionista) com **KPIs do dia** (Entradas, Saídas, Sangrias, Suprimentos), **card destacado de Saldo** (verde quando positivo, vermelho quando negativo) e **lista de movimentações** com setas e cor por tipo.
- **Botão "Nova movimentação"** abre um menu com 4 opções: **Entrada**, **Saída**, **Sangria** e **Suprimento**. Cada uma abre um formulário com descrição, valor, forma de pagamento (Dinheiro / PIX / Crédito / Débito / Boleto / Transferência) e observações.
- **Trocar dia** pelo calendário no canto superior direito pra ver o caixa de qualquer data anterior.
- **Excluir movimentação** manual com confirmação. Movimentações automáticas (geradas por PDV, Pagamento ou Despesa) ficam marcadas com etiqueta "Auto" e não podem ser apagadas pelo módulo de Caixa.

### Melhorias

- Pull-to-refresh recarrega o caixa do dia.
- Dados zeram ao trocar de academia/unidade.

---

## AlfaMobi — 26/04/2026 — CRUD de Planos AlfaGym (Fase C3c)

### Novidades

- Tela de **Planos** ganha botão **"Novo plano"** no canto inferior direito.
- Detalhe do plano agora abre **menu de ações** (Editar / Duplicar / Inativar).
- **Formulário de plano** com 7 seções: Identificação, Preço+Duração, Tipo+Acesso, Modalidades, Cancelamento+Fidelidade, Mobilidade e Promoção.
  - Marca **modalidades** disponíveis em chips (Musculação, CrossFit etc.).
  - Marca **dias da semana** liberados (vazio = livre todos os dias).
  - Configura fidelidade mínima, multa de cancelamento (%), trancamento (com dias máximos), permissões de transferência/upgrade/downgrade.
  - **Promoção opcional** com preço promocional + data de validade.
- **Inativar** com diálogo de confirmação que avisa quantos alunos estão vinculados; o plano fica oculto pra novas matrículas mas alunos ativos seguem normalmente.
- **Duplicar** cria um clone com sufixo "(cópia)".

### Melhorias

- Mensagens de erro inesperado trocam stacktrace por "Não foi possível salvar. Tente novamente." (detalhes só em log).
- Service de Planos passa a usar a humanização de erros padrão do app.

---

## AlfaMobi — 26/04/2026 — Relatórios Caixa + Contratos + Produtos + Comissões (Fase C6c.3)

Fecha o bloco de Relatórios — todos os **9 relatórios** do AlfaGym agora estão funcionais no app.

### Novidades

- Tile **Caixa** abre tela com KPIs (Entradas, Saídas, Saldo do período, Ticket médio), Sangrias/Suprimentos, **entradas por forma de pagamento** (PIX, crédito, dinheiro etc.), entradas por origem, saídas por categoria e **últimas movimentações** (com setas de entrada/saída coloridas).
- Tile **Contratos** abre tela com **base atual** (Ativos, Vencendo nos próximos 30 dias, MRR, Previsão de receita), movimentação no período (Novos, Renovações, Cancelamentos, Vencidos), **indicadores** (Taxa de renovação, Churn, Permanência média), por plano, **contratos vencendo em breve** (com pill de dias coloridas) e cancelamentos recentes (com motivo).
- Tile **Produtos** abre tela com Receita total e Unidades vendidas, **mais vendidos** e **receita por produto**.
- Tile **Comissões** abre tela com Total de vendas, Comissões devidas, Quantidade, Por tipo (Matrícula/Renovação/Produto/Serviço), **Ranking de vendedores** (com posição) e **detalhe por funcionário** (quantidade/total/comissão/ticket).

### Melhorias

- Mesmo seletor de período (calendário no canto superior direito) e pull-to-refresh em todas as telas.
- Dados zeram ao trocar de academia/unidade.

---

## AlfaMobi — 26/04/2026 — Relatórios Frequência + Acessos (Fase C6c.2)

### Novidades

- Tile **Frequência** dos Relatórios passa a abrir uma tela com **2 KPIs** (total de acessos no período e média diária) + **barras horizontais** mostrando os acessos por dia da semana e por hora do dia.
- Tile **Acessos** dos Relatórios passa a abrir uma tela com **4 KPIs** (total de acessos, pessoas distintas, média diária, média por aluno) + **card de variação percentual** comparando com o período anterior + barras por dia da semana e por origem + **Top alunos** e **Top funcionários** (cartões com iniciais, plano/matrícula e último acesso).

### Melhorias

- Mesmo seletor de período (calendário no canto superior direito) já usado nos relatórios anteriores.
- Pull-to-refresh em ambas as telas.
- Dados zeram ao trocar de academia/unidade.

---

## AlfaMobi — 26/04/2026 — Relatórios Financeiro + Alunos (Fase C6c.1)

### Novidades

- Tile **Financeiro** dos Relatórios passa a abrir uma tela com **4 KPIs do período** (Receita, Despesa, Lucro e Margem em %), gráfico em lista da **receita por mês** e da **despesa por categoria**. Padrão visual idêntico ao relatório de Inadimplência.
- Tile **Alunos** dos Relatórios passa a abrir uma tela com **base de alunos** (Ativos / Suspensos / Cancelados / Inativos) + **movimentação no período** (Novos / Cancelados) + listagens **novos por mês** e **alunos por plano**.

### Melhorias

- Os relatórios respeitam o **mesmo seletor de período** (calendário no canto superior direito) já usado em Inadimplência; a seleção é mantida ao trocar de tela.
- Pull-to-refresh em ambas as telas.
- Dados zeram ao trocar de academia/unidade.

---

## AlfaMobi — 26/04/2026 — Equipe + Provisionar revenda + Form de planos (Fase C7g)

### Novidades

- Novo tile **Equipe** (super_admin) no painel SaaS do AlfaGym pra gerenciar funcionários internos da Alfa Soluções: lista com **busca por nome ou e-mail**, **filtros por status** (Ativo / Inativo / Afastado / Desligado) e cartões com avatar pelas iniciais (cor pelo status), tipo, cargo e contato.
- **Cadastro/edição de funcionário** em formulário com 4 seções: **Dados** (CPF, e-mail, telefone), **Vínculo** (tipo: administrador / gerente / recepcionista / professor / prestador), **Acesso ao sistema** (com e-mail e senha de login quando habilitado) e **Observações internas**.
- **FAB "Provisionar"** na lista de Tenants abre formulário pra criar **revenda + admin numa única operação**: dados da empresa, endereço completo (CEP, logradouro, número, bairro, cidade, UF) e dados do administrador (nome, e-mail, senha de no mínimo 8 caracteres).
- **FAB "Novo plano"** na tela de Planos SaaS e **toque no plano** abrem o **formulário de plano** com nome, slug, preço mensal, limites (alunos / usuários / unidades), JSON de features e ativo/inativo. Editar permite **inativar o plano** via menu — tenants já vinculados continuam usando.

### Melhorias

- **Validador de senha do funcionário** exige senha quando você liga "Tem login no sistema" pela primeira vez (em edição). Antes era possível salvar sem senha, deixando o usuário sem como entrar.
- **Campos de senha** marcados como "nova senha" pro gerenciador de senhas do celular sugerir uma forte; sugestões automáticas e autocorreção desligadas pra evitar vazar a senha em logs do teclado.
- **Mensagens de erro inesperadas** trocam o stacktrace técnico por "Não foi possível salvar. Tente novamente." (detalhes ficam só no log de diagnóstico).
- Dados de Equipe zeram ao trocar de academia/unidade, igual aos demais módulos.

---

## AlfaMobi — 26/04/2026 — Manutenção + Configurações do sistema (Fase C7f)

### Novidades

- Novo tile **Manutenção** (super_admin) no painel SaaS do AlfaGym permite **ativar/desativar o modo manutenção** do sistema com agendamento opcional (data e hora de início e fim). Um banner mostra o status atual (em manutenção / operacional) e o tempo restante até terminar.
- Novo tile **Configurações do sistema** (super_admin e admin_revenda) com **três abas**:
  - **Horário**: define os horários de atendimento de cada dia da semana (formato `HH:MM-HH:MM`). Banner indica se estamos abertos agora, fechados ou se o controle está desligado. Inclui exibição do feriado de hoje e do próximo horário.
  - **Exceções**: cadastra datas com tratamento especial (fechado por feriado interno, recesso, ou horário diferente). Lista ordenada por data com motivo e badge.
  - **Feriados**: navega ano a ano e mostra os feriados nacionais consultados em tempo real, com dias passados acinzentados.

### Melhorias

- Pull-to-refresh em Configurações > Horário recarrega os dados sem perder o formulário em caso de falha.
- Validação client-side do formato `HH:MM-HH:MM` (hora de início < hora de fim, minutos válidos) avisa antes de tentar salvar.
- Dados zeram ao trocar de academia/unidade.

---

## AlfaMobi — 25/04/2026 — Avisos administrativos (Fase C7e)

### Novidades

- Novo tile **Avisos** no painel SaaS do AlfaGym (super_admin e admin_revenda) pra publicar **comunicados** pra revendas e academias da rede.
- Cada aviso tem **título, conteúdo, nível** (Info, Alerta, Urgente — com cor) e **escopo**: Todos / Todas as revendas / Apenas a minha revenda / Revenda específica / Academia específica.
- **Data de expiração opcional** com seletor de data e hora; avisos expirados aparecem com indicador "Expirou".
- Lista paginada com infinite scroll. Cada cartão mostra autor, data de criação, badge "Inativo" quando desativado e menu pra editar/desativar.

### Melhorias

- Pull-to-refresh em Avisos preserva a lista em tela quando a atualização falha.
- Os dados zeram ao trocar de academia/unidade.

---

## AlfaMobi — 25/04/2026 — Remoção da seção de Leads

### Melhorias

- O painel SaaS do AlfaGym deixa de exibir o tile **Leads** e o grupo "Comercial". A landing pública nunca chamou o backend pra cadastrar leads — os formulários de interesse já redirecionam direto pro WhatsApp. A tela mobile, a aba/cards do painel web e os endpoints/tabela do backend foram removidos pra eliminar uma seção sem dados reais.

### Notas técnicas (não afetam o usuário)

- O CRM **Interessados** da própria academia (fila de prospectos em virar alunos) **continua funcionando normalmente** — escopo diferente, fonte distinta.

---

## AlfaMobi — 25/04/2026 — Planos + Licenças (Fase C7c)

### Novidades

- **Planos** (super_admin): novo tile no painel SaaS com a lista dos planos comerciais. Cada cartão mostra nome, identificador, preço mensal em destaque, limites de alunos/usuários/unidades e badge **Ativo / Inativo**.
- **Licenças** (super_admin): novo tile com duas abas:
  - **Pendentes**: academias aguardando liberação. Cada cartão mostra nome, CNPJ, revenda, cidade/UF e o plano solicitado. Botão **Liberar** abre diálogo com seleção de plano (dropdown), tipo (Mensal/Anual), valor e observações. Validação não deixa passar valor negativo nem formato inválido.
  - **Ativas**: licenças vigentes com badge de status (Ativo / Em trial / Em atraso / Suspenso / Cancelado) + badge de **dias restantes** (vermelho se ≤ 7 ou vencida, laranja ≤ 15, verde > 15). Cada cartão mostra plano, tipo, valor e período. Botão **Renovar** com mesmo formulário do Liberar.

### Melhorias

- Status das licenças exibido em PT-BR (igual ao padrão dos Tenants).
- Renovar/Liberar atualiza imediatamente as duas listas (pendentes e ativas) sem precisar recarregar.

---

## AlfaMobi — 25/04/2026 — Tenants ações + Revendas (Fase C7b)

### Novidades

- **Tenants**: tocar num cartão abre o detalhe com plano, datas (trial e próxima cobrança), uso (alunos/unidades), contato e botão **"Mudar status SaaS"**. O super_admin escolhe entre Em trial / Ativo / Suspenso / Cancelado e pode anexar um motivo opcional. A mudança aparece imediatamente na lista.
- **Revendas**: novo tile no painel SaaS do AlfaGym (super_admin) lista as revendas com busca por nome, CNPJ, e-mail, razão social ou nome fantasia. Cada cartão mostra avatar de iniciais (cor por status), CNPJ, número de academias, admin (nome/e-mail), telefones, cidade/UF, percentual de comissão e botão **"Reset senha"** pra redefinir o acesso do admin.
- O reset de senha valida no app que a senha tenha pelo menos 8 caracteres e mostra mensagem do backend em caso de erro.

### Melhorias

- Pull-to-refresh em Revendas; lista preserva dados em tela quando a atualização falha.
- Dados ficam zerados ao trocar de academia/unidade.

---

## AlfaMobi — 25/04/2026 — Polish da lista de Tenants (C7a.1)

### Melhorias

- **Lista de Tenants** ganha visual mais limpo: cada tenant agora aparece como cartão com avatar circular (inicial em cor de status), nome em destaque, plano e preço/mês em bloco azul-laranja, **barras de progresso** compactas pra alunos (X/Y) e unidades, e seção de datas (trial e próxima cobrança) só quando aplicável.
- **Filtros de status** com rótulos em **português** (Ativos, Em trial, Em atraso, Suspensos, Cancelados) e cor do status quando selecionado, com pequena animação no toque.
- **Status no cartão** também em português (Ativo, Em trial, Em atraso, Suspenso, Cancelado).
- Filtros agora aparecem em ordem alfabética (sem ficar pulando entre atualizações).

---

## AlfaMobi — 25/04/2026 — Painel SaaS AlfaGym: Dashboard + Tenants (Fase C7a)

### Novidades

- O painel SaaS do AlfaGym (visível pra **super_admin** logado pelo AlfaGym) ganha duas telas reais:
  - **Dashboard SaaS**: indicadores de receita (MRR, ARR, ARPU, LTV) + contagem de tenants por status (ativos, em trial, em atraso, suspensos, cancelados) + saúde da operação (total + taxa de churn mensal, destacada em vermelho quando > 5%).
  - **Tenants**: lista das academias contratantes com busca por nome/CNPJ/e-mail, filtros dinâmicos por status, e cartão por tenant mostrando plano, preço/mês, alunos, unidades, fim do trial e próxima cobrança.
- Os outros 8 tiles do painel (Revendas, Licenças, Planos, Leads, Avisos, Manutenção, Equipe, Configurações) ficam visíveis com selo "Em breve" — implementação dedicada vem nas próximas fases.

### Melhorias

- Pull-to-refresh em Dashboard e Tenants atualiza os dados sem perder o que já estava em tela em caso de falha de rede.
- Os dados ficam zerados ao trocar de academia/unidade (sem mostrar números do tenant anterior).

---

## AlfaMobi — 25/04/2026 — Relatórios do AlfaGym + painel SaaS por sistema

### Novidades

- Tile **Relatórios** no Hub Operacional do AlfaGym (admin/gerente) agora abre uma lista com 9 relatórios. O primeiro disponível é **Inadimplência**:
  - 4 indicadores no topo: total de inadimplentes, valor em aberto, % de inadimplência e cobranças vencidas.
  - **Atraso por faixa** (1-7 dias, 8-15, 16-30, 31-60, 60+) com quantidade e valor.
  - **Por plano**: quantos alunos inadimplentes e valor em aberto agrupados por plano.
  - **Top devedores**: lista com nome, telefone, dias de atraso, vencimento mais antigo e valor — pronto pra recepção/gestão entrar em contato.
  - Período personalizável (range picker) e pull-to-refresh.
- Os outros 8 relatórios (Financeiro, Caixa, Alunos, Frequência, Contratos, Acessos, Produtos, Comissões) ficam visíveis com selo "Em breve" até a próxima fase.

### Correções

- **Painel SaaS por sistema**: AlfaControl e AlfaGym são SaaS independentes, cada um com seu próprio painel administrativo. Antes, super_admin que logava pelo AlfaGym via o painel do AlfaControl e batia em endpoints inexistentes — Revendas/Clientes/Usuários/Auditoria mostravam "Não foi possível carregar". Agora o app detecta o sistema do login: pelo AlfaControl mostra o painel completo (intacto); pelo AlfaGym mostra um painel próprio listando Tenants, Revendas, Licenças, Planos, Leads, Avisos, Manutenção, Equipe e Configurações como "Em breve" — implementação dedicada vem em fase futura.

---

## AlfaMobi — 25/04/2026 — Correção: login super_admin no AlfaGym

### Correções

- Login com perfil **super_admin** no AlfaGym caía indevidamente na tela "Escolha a unidade", impedindo o acesso ao SaaS Shell. Agora super_admin, super_user e admin_revenda vão direto pro painel SaaS, ignorando qualquer lista de unidades vinda do backend (essa lista alimenta apenas o Hub SaaS, não o fluxo de login).

---

## AlfaMobi — 25/04/2026 — Dashboard do AlfaGym (Fase C6a)

### Novidades

- Novo tile **Dashboard** no Hub Operacional do AlfaGym, disponível para **administrador e gerente**. Ao abrir, a tela mostra um panorama completo da academia em uma única página, com **pull-to-refresh** e seletor de período (Hoje, Últimos 7 dias, Últimos 30 dias, Mês atual).
- **Hoje** (4 indicadores): alunos presentes, valor recebido, despesas e faturas em atraso.
- **Base de alunos**: total de ativos, comparação com o mês anterior (variação absoluta + percentual), novos no mês, cancelamentos e alunos em risco de cancelamento (destacado em vermelho quando > 0).
- **Financeiro**: receita do período, ticket médio, saldo bancário, taxa de inadimplência (destacada em vermelho acima de 10%) e taxa de retenção.
- **Alertas da academia**: lista de alertas ativos com cor por severidade (informativo, atenção, crítico) e badge com a quantidade de itens afetados.
- **Aniversariantes** do período + contagem de **contratos vencendo nos próximos 30 dias**.

### Melhorias

- O Dashboard fica zerado ao trocar de academia ou unidade (sem mostrar números do tenant anterior por uma janela).

---

## AlfaMobi — 25/04/2026 — Treinos (AlfaGym) temporariamente "Em breve"

### Aviso

- O módulo **Treinos** do AlfaGym está sendo **reformulado** para uma próxima versão. Até lá, o tile continua visível no Hub Operacional, mas ao abrir mostra a tela "Em breve. O módulo de Treinos está sendo reformulado." Nenhum dado de treino é perdido — o módulo apenas sai de circulação enquanto a nova versão é construída.
- Demais módulos do AlfaGym (Alunos, Check-in, Planos, Contratos, Financeiro) continuam funcionando normalmente.

---

## AlfaMobi — 25/04/2026 — Integração AlfaGym (Bloco A → F → B → C)

Esta versão entrega a primeira leva funcional da **integração com o AlfaGym** (academia) no mesmo aplicativo que já roda o AlfaControl (condomínio). 18 fases concluídas em sequência ao longo do dia, todas commitadas em `main` com testes verdes (suíte saiu de 341 → 558 testes).

### Novidades

**Login e seleção pós-login**
- O AlfaGym agora reconhece os perfis da academia: **admin, administrador, gerente, recepcionista** e **professor** entram no app com o Hub Operacional próprio (em vez de cair no fluxo do morador/Pessoa).
- **Admin de revenda** (rede com várias academias) ganha tela "Escolha a academia" pós-login. Ao selecionar uma, o app entra no contexto daquela academia.
- Academias com mais de uma **filial (unidade)** mostram tela "Escolha a unidade" depois do login (ou da troca de academia). Quando a academia tem só uma filial, o app pula automaticamente.

**Hub Operacional do AlfaGym**
- Aba "Operação" exibe os tiles que o seu perfil pode usar — definidos por uma matriz de permissões idêntica em conceito à do AlfaControl (admin/gerente vê tudo; recepcionista atende balcão; professor só os próprios alunos e treinos).

**Alunos**
- Lista paginada com busca por nome ou CPF, scroll infinito e filtros de status (todos/ativos/inativos/suspensos/trancados).
- Detalhe completo: contato, endereço, plano vigente, histórico de saúde, contato de emergência, professor responsável, observações.
- **Criação e edição** de aluno via formulário com validação local de CPF, telefone, e-mail, CEP e UF (mesmas regras do servidor — evita ida e volta com mensagens técnicas).
- **Foto do aluno** pode ser tirada pela câmera ou escolhida da galeria, e enviada direto pra ficha.
- **Inativação** com confirmação (ADMIN/GERENTE; recepcionista não inativa).
- **Perfil agregado** de uma tela: contrato ativo + faturas em aberto + presenças do mês + status financeiro (em dia / inadimplente).

**Check-in (recepção)**
- Busca instantânea de aluno por nome/CPF; ao tocar, abre painel de validação com **adimplência, biometria, plano vigente, limite semanal e alertas** — recepcionista vê tudo antes de liberar.
- Botão de "Liberar" muda pra vermelho ("Liberar mesmo assim") quando há problema, deixando claro que é uma exceção.
- Após validar, escolhe o motivo (esqueceu biometria, problema na catraca, exceção autorizada, cortesia, day use, aula experimental, outro).
- Feed do dia abaixo mostra todos os check-ins registrados em ordem cronológica.

**Planos**
- Lista de todos os planos da academia com chips de filtro (todos/ativos/inativos), preço efetivo (com promoção quando ativa) e quantidade de alunos vinculados.
- Detalhe agrupa em seções: cobrança, duração e fidelidade, regras de acesso (incluindo limite semanal e dias da semana liberados), modalidades, regras de trancamento/transferência/upgrade/downgrade.

**Contratos e Matrículas**
- Lista geral de contratos com status colorido (ativo / trancado em cinza / cancelado em vermelho).
- Recepcionista cria **nova matrícula** via formulário: busca o aluno, escolhe o plano, define data de início e os opcionais (desconto, forma de pagamento, dia de vencimento, observação).
- ADMIN/GERENTE renovam, **cancelam** (com motivo opcional), **trancam** (com data de início e fim + motivo) ou **destrancam** contratos diretamente do detalhe.

**Financeiro — Recebíveis**
- Lista os recebíveis (créditos pendentes/recebidos de pagamentos) com filtros de status (todos/pendentes/recebidos) e seletor de período (data range picker).
- Header mostra o **total pendente** somado dos itens visíveis (esconde quando o filtro é "Recebidos" pra não confundir).
- Botão "Limpar período" aparece quando há filtro de datas aplicado.
- ADMIN/GERENTE/RECEPCIONISTA marcam um recebível como **recebido**, escolhendo a data efetiva do crédito.

**Treinos (modelos)**
- Lista de modelos de treino cadastrados na academia, com nome e descrição.
- Detalhe completo: cada exercício com **série × repetições** (ou AMRAP), **descanso** entre séries, percentual de 1RM, RPE alvo, RIR alvo, tempo prescrito (cadência) e tipo de série.
- **Supersets aparecem agrupados visualmente** — exercícios marcados com a mesma letra (A, B1, etc.) ficam num bloco com bordura colorida e label "SUPERSET A".
- Chips com ícones identificam descanso/percentual/RPE/RIR/tempo de relance.

### Segurança e proteção entre clientes

A integração foi feita pensando que o app é um SaaS multi-tenant: o mesmo app é usado por várias academias de várias revendas, e nada de uma pode aparecer pra outra. Reforços:

- **Listas de cache** de cada feature (alunos, planos, contratos, recebíveis, etc.) são **zeradas automaticamente** ao trocar de academia/unidade ou fazer logout — sem isso, dados da academia anterior poderiam aparecer por uma janela na nova.
- **Auditoria silenciosa** das respostas do servidor: o app compara IDs de revenda/academia/unidade que vierem no corpo da resposta com o tenant da sessão atual. Se divergir, registra log em modo debug pra detectar bug de filtro do servidor antes que vire vazamento real (com proteção contra spam: mesma divergência só é logada uma vez a cada 30s).
- **Gates por features contratadas no plano SaaS**: tiles que dependem de funcionalidade contratada (ex.: "Treinos", "Avaliações") só aparecem se o plano da academia incluir. Hoje o servidor ainda não envia essa lista — o app mantém tudo liberado e o filtro entra em vigor automaticamente quando o servidor for atualizado.
- Mensagens de erro do servidor são **sanitizadas** antes de aparecer pro usuário: traços técnicos (stack trace, SQL, exceções Java) são descartados em favor de copy genérica.
- Erros de validação por campo (ex.: "CPF inválido") são traduzidos pra português com nome amigável: o backend devolve `telefoneSecundario` e o app mostra "Telefone secundário".

### Melhorias

- Botão de "Sair" disponível tanto na tela de seleção de academia quanto na de seleção de unidade — você pode cancelar o login em qualquer ponto desse fluxo.
- Diálogos de confirmação em **inativar aluno**, **cancelar contrato**, **trancar contrato** e **destrancar contrato** evitam ações acidentais.
- Após inativar/cancelar/trancar, a lista é atualizada na hora — sem precisar puxar pra recarregar.
- Date pickers com limites razoáveis (não permite trancar contrato com data muito no passado ou no futuro).

### Correções (descobertas e corrigidas durante a integração)

- Vazamento entre sessões corrigido: ao trocar de academia, dados da academia anterior poderiam permanecer em memória até o próximo carregamento. Agora o app limpa antes de chamar o servidor.
- `notificarAcessos` antigamente cuidava de 3 coisas no AlfaControl — separamos em flags próprias antes da integração começar (já estava na versão de 24/04).
- Fluxo de admin de revenda no AlfaGym: se o app fosse fechado durante a tela de seleção de academia, ao reabrir ele reentrava direto na Home sem academia escolhida — corrigido (volta pra tela de seleção).
- Mensagem de erro no upload de foto, exclusão e edição de aluno passa por filtro: respostas com stack trace técnico do servidor são substituídas por copy genérica.

### Cronograma técnico (commits)

Cada bloco abaixo é um commit em `main`, com horário local (UTC-3) e suíte de testes ao final:

**Bloco A — Fundação RBAC (matriz de permissões + roteamento)**
- `e79e01e` 10:21 — `SessionType` reconhece perfis AlfaGym (A1).
- `02ffa21` 10:31 — Split `PerfilPermissions` em `PerfilCondoPermissions` + `PerfilGymPermissions` (A2).
- `b6f18f2` 10:39 — `ModuleCatalog.forGymHub` com gate perfil ∩ features contratadas (A3).
- `c0e7185` 10:48 — `MainShell` ramificado por produto + `OperacaoGymHubScreen` (A4).

**Bloco F — Multi-tenant SaaS hardening**
- `0b408fe` 10:57 — `tenantFeatures` no `MeProfile`/`AuthProvider` (F1).
- `1477667` 11:17 — `Clearable` interface + `clearAll` + 22 providers (F2).
- `c36d3ae` 11:30 — Auditoria cross-tenant em respostas do backend (F3).

**Bloco B — Multi-tenant pós-login**
- `ca24135` 11:41 — Selecionar academia (admin_revenda Gym) (B1).
- `239da7d` 15:30 — Selecionar unidade (filiais) (B2).
- `6644ac6` 15:33 — Refator: extrai `_trocarTenant` para DRY entre B1/B2.

**Bloco C — Funcionário primeiro**
- `ffba51a` 15:43 — Alunos read-only: lista paginada + busca + detalhe (C1a).
- `dbf7d0d` 15:56 — Alunos escrita: form, inativar, perfil agregado, filtros (C1b).
- `c033e29` 16:05 — Foto upload + validação client-side + `Provider<AlunosService>` (C1c).
- `a885a57` 16:16 — Check-in: busca, validação, registro manual, feed do dia (C2).
- `7b2b9a8` 16:25 — Planos read-only: lista + detalhe agregado (C3a).
- `d29ac79` 16:36 — Contratos + Matrículas: lista, detalhe, criar, renovar/cancelar/trancar/destrancar (C3b).
- `a3e576a` 16:44 — Recebíveis: lista com filtros + marcar como recebido (C4).
- `da7f14c` 16:57 — Treinos read-only: templates + detalhe com supersets (C5).

Suite de testes: **341 → 558** (217 testes novos cobrindo modelos, parsers, função pura `precisaSelecionarAcademia`/`precisaSelecionarUnidade`, gates de permissão, helpers de status/promoção/atraso, agrupamento de supersets). `flutter analyze` 100% limpo. Cada fase passou pelo `/revisor` (5 agentes em paralelo: segurança, correção, convenções, testes, arquitetura) com bloqueantes corrigidos antes do commit.

---

## AlfaMobi — 24/04/2026 — Preferências de notificação separadas para morador

### Novidades
- Tela de **Preferências de notificações** agora adapta as opções ao seu perfil:
  - **Morador, aluno ou pessoa cadastrada**: dois avisos independentes — **"Meus acessos"** (quando você passa em um leitor) e **"Acessos de dependentes"** (quando alguém sob sua responsabilidade passa). Antes, havia um único controle e ativar uma coisa ligava a outra também
  - **Gestor, porteiro, recepcionista e operador**: mantém os controles antigos (avisos de acessos do condomínio/escola/empresa e alerta de acessos não identificados)

### Correções
- Tela de Preferências de notificações dava erro "Não foi possível carregar" quando aberta por **morador** — o servidor não aceitava o perfil. Corrigido

## AlfaMobi — 24/04/2026 — QR Visitante passa a ser gerado pela Portaria

### Melhorias
- O tile **"QR Visitante"** saiu do atalho rápido na Home do morador: a geração do QR para visitantes agora é feita pelo **porteiro** (ou operador) em nome da pessoa solicitante. Essa mudança garante rastreabilidade correta dos convites e impede geração indevida de QR por terceiros
- Se você usa o app como morador e precisa de QR para um visitante, fale com a portaria — a tela de geração para operadores será lançada em versão futura

### Segurança
- Endpoints do servidor que estavam abertos a qualquer usuário autenticado passaram a exigir o perfil correto: Veículos, Eventos manuais, Documentos, Regras de Acesso, Tipos de Pessoa, Perfis da Pessoa, Face, Dependentes, Dashboard, Notificações, QR Code, e áreas administrativas do SaaS (Planos, Assinaturas, Tenants, Métricas, Dados)
- Dependentes: morador deixa de conseguir cadastrar ou remover vínculos diretamente — a conversa passa pelo gestor do cliente

### Correções
- Corrige caso em que uma Pessoa tinha acesso ativo ao app, mas o usuário de login dela havia sido removido: agora, ao redefinir a senha pelo gestor, o acesso é recriado automaticamente (antes aparecia erro "Recrie pelo módulo Usuários")

## AlfaMobi — 24/04/2026 — Vincular perfis em lote + fotos na Portaria ao vivo

### Novidades
- Na tela de **Perfis de Acesso da pessoa** (dentro do cadastro), o botão "Adicionar" agora abre uma tela com **busca** e permite **marcar vários perfis de uma vez** com checkboxes. Antes, cada perfil precisava ser adicionado individualmente reabrindo o dialog
- Cada item da lista mostra um resumo do perfil ("Sem expiração", "5/dia" etc.) para ajudar na escolha
- O botão confirma com contagem: "Adicionar 3 perfis"; o app vincula todos em paralelo e mostra um único aviso no final ("3 perfis vinculados" ou, em caso de falha parcial, "3 de 5 vinculados — 2 falharam")

### Correções
- **Portaria ao vivo**: foto da pessoa voltou a aparecer no feed. A decodificação de imagens vindas em base64 estava travando silenciosamente; agora funciona tanto para URLs HTTP quanto para imagens embutidas

## AlfaMobi — 24/04/2026 — Aba Menu repaginada e terminologia do seu segmento

### Novidades
- Aba **Menu** totalmente redesenhada: o cabeçalho agora mostra sua **foto, nome e perfil** com destaque, e o conteúdo está agrupado em seções claras — **Conta** (Editar perfil, Alterar senha, Preferências de notificações), **Preferências** (Tema), **Sobre** (Sobre o app) e **Sair** em destaque vermelho
- Novo item **"Sobre o app"** abre um painel com o logotipo, a versão instalada e os créditos da Alfa Soluções
- **Moradores, alunos e pessoas em geral** agora também têm acesso a **Preferências de notificações** (antes era só para perfis operacionais) — você pode controlar quais avisos de acesso quer receber
- A identificação do seu **segmento** passou a refletir o tipo de organização onde você usa o sistema: escola, empresa, clube, condomínio ou academia. Antes, muitos textos mencionavam "condomínio" mesmo quando o cliente era de outro segmento

### Melhorias
- Grid antigo com 4 tiles inativos ("Dados cadastrais", "Dados da instituição", "Privacidade", "Sobre") foi removido em favor do novo Menu organizado por seções
- Copy de telas diversas (dialog de "Esqueci minha senha", Preferências de notificações, erros do QR Visitante) agora usa linguagem neutra ou específica do seu segmento, ao invés de "condomínio" hardcoded

## AlfaMobi — 23/04/2026 — Histórico de notificações com filtros

### Novidades
- Tela de Notificações agora tem **busca** (título ou mensagem), **chips de status** (Todas / Não lidas / Lidas, com contador) e **chips de tipo** (Acesso, Encomenda, etc — gerados automaticamente a partir das notificações que você recebeu)
- Botão novo no topo da tela (ícone de ajuste) abre **filtros avançados** com janela de data (início e fim) pra encontrar notificações antigas
- Cada notificação no card ganhou **etiqueta do tipo** ao lado da data (antes só aparecia como bolinha de "lida/não lida")

### Melhorias
- Ícones do card passam a refletir o tipo real da notificação — acesso virou porta, encomenda virou caixa, manutenção virou chave inglesa (antes caía no ícone genérico de sino pra a maioria dos tipos)
- Estado vazio fica contextual: com filtros ativos oferece um botão "Limpar filtros" direto; sem filtros mantém "Você está em dia"

## AlfaMobi — 23/04/2026 — Resumo de hoje na Home (Dashboard real)

### Novidades
- O bloco "Dashboard" na Home do Gestor do Cliente virou **"Resumo de hoje"** e agora mostra **números reais**: Entradas, Saídas, Visitantes ativos e **Negados** (em vermelho), contados até o momento atual do dia
- Puxar a tela pra baixo (pull-to-refresh) atualiza os 4 cards junto com o feed de últimos acessos

### Melhorias
- Os 4 cards vinham mostrando "—" desde o começo do app porque as métricas antigas ("Permanência", "Total de acessos", "Dias com acessos", "Acessos bloqueados" no mês) nunca tinham backend. Trocadas por indicadores que existem e fazem sentido pro operacional do dia-a-dia

## AlfaMobi — 23/04/2026 — Auditoria no app

### Novidades
- Nova tela de **Auditoria** disponível pra Gestor do Cliente, Admin de Revenda e Super Admin — histórico completo de ações registradas no sistema (logins, criações, edições, exclusões, trocas de senha, sincronizações, etc.)
  - Filtros por **módulo** (Pessoas, Dispositivos, Clientes, Autenticação, etc.), **ação** (Login, Criação, Atualização, Exclusão…), **entidade**, **ID do usuário** e **janela de datas**
  - Cada evento mostra badge colorido por tipo (verde/vermelho/amarelo/azul), módulo, usuário responsável, entidade afetada e timestamp
  - Ao tocar em um evento, abre o **detalhe completo** com descrição, IP, user-agent e — quando o evento representa uma alteração — os dados anteriores e os novos em JSON formatado, com botão pra copiar
- Entry points: **tile "Auditoria"** no painel SaaS (Super Admin e Admin de Revenda) e **card "Auditoria"** na Home do Gestor do Cliente (logo abaixo do card Logs de Acesso)
- Porteiro, Recepcionista, Operador e Morador **não** têm acesso — eventos contêm dados sensíveis e ações de outros usuários

### Segurança
- Endpoint de auditoria no servidor estava **sem verificação de perfil** — qualquer usuário autenticado conseguia ler auditoria inteira do próprio tenant. Corrigido: apenas Gestor do Cliente, Admin de Revenda e equipe Alfa têm acesso, bloqueio aplicado também no backend (defesa em profundidade)

## AlfaMobi — 23/04/2026 — Logs de Acesso: card destacado + filtros por data

### Novidades
- **Card "Logs de Acesso"** destacado no topo da Home pra quem opera o sistema (porteiro, recepcionista, operador, gestor, administradores) — um toque leva direto ao histórico completo de passagens
- Tela agora tem **filtros por data** (início e fim) além da busca por pessoa, dispositivo e resultado que já existiam
- O tile "Eventos" foi renomeado pra **"Logs de Acesso"** (nome mais claro — a tela sempre foi o histórico, não o tempo real)

### Melhorias
- Quem opera o sistema deixa de ver o tile duplicado: o card destacado substitui o tile no grid "Acesso rápido", evitando dois caminhos pra mesma tela. Morador continua com o tile (vê só os próprios eventos)
- Diferença com a **Portaria ao vivo** ficou mais clara: Portaria = acompanhar passagens em tempo real e registrar entradas manuais; Logs de Acesso = investigar o histórico já registrado

## AlfaMobi — 23/04/2026 — Usuários: filtro por revenda e cliente (Super Admin)

### Novidades
- Super Admin agora pode **filtrar a lista de Usuários por revenda e/ou cliente**, além da busca por nome/e-mail que já existia
  - Botão de filtro no topo da tela abre um menu com os pickers de revenda e cliente (busca embutida em cada picker)
  - Selecionar uma revenda filtra automaticamente o picker de cliente pra essa revenda
  - Limpar revenda também limpa o cliente vinculado (mantém os filtros coerentes)
- Cada usuário no card mostra a qual **cliente** e **revenda** pertence, facilitando identificar tenants de relance
- **Chips removíveis** acima da lista mostram os filtros ativos — um toque no X desliga o filtro
- Filtros por perfil (Super, Revenda, Gestor, Operador, Porteiro) continuam disponíveis junto com os novos

## AlfaMobi — 23/04/2026 — Configurações de conta + Dashboard pro Admin de Revenda

### Novidades
- Nova tela **Configurações** (acessível pelo Menu, disponível para todos os perfis):
  - **Meu perfil**: avatar com iniciais, nome, e-mail e selo do perfil
  - **Editar perfil**: alterar nome e/ou e-mail (sem precisar fazer logout)
  - **Alterar senha**: trocar senha proativamente, sem depender de senha provisória — basta digitar a nova e confirmar
- Admin de Revenda agora tem **Dashboard** próprio (3 abas no painel: Dashboard + SaaS + Menu, antes só 2)
  - Dashboard mostra apenas o que faz sentido para a revenda: MRR das licenças, total de clientes (ativos/aguardando licença) e licenças (ativas/vencendo em 7 dias) — todos os números filtrados pela própria revenda
  - Métricas globais (MRR/ARR do SaaS, churn, ARPU, LTV, totais de tenants) continuam exclusivas do Super Admin

## AlfaMobi — 23/04/2026 — Painel SaaS para Admin de Revenda

### Novidades
- O perfil **Admin de Revenda** agora consegue operar a revenda direto pelo aplicativo, com painel próprio adaptado ao papel
- Hub do admin de revenda mostra 4 módulos:
  - **Minha Revenda**: abre direto a ficha da revenda (dados cadastrais, admin de contato), com botão Editar
  - **Clientes**: lista completa dos clientes da revenda, com cadastro/edição/exclusão e ações de AlfaSync (gerar Agent ID, credenciais)
  - **Backup**: dropdown de cliente no topo; ao escolher, mostra os backups disponíveis daquele cliente e permite restaurar. Disparar backup por cliente também disponível
  - **Documentação**: WebView da documentação completa do AlfaControl
- Tiles que não fazem sentido para admin de revenda foram ocultados: **Licenças** (gestão da Alfa), **Usuários** (gerenciados pelo gestor de cada cliente), **Manutenção** e **Planos** (somente Super Admin)
- Aba **Dashboard** também não aparece para admin de revenda (sem métricas globais, fica para fase futura quando houver indicadores específicos da revenda)
- Em "Minha Revenda", botões de "Excluir revenda" e "Resetar senha do admin" não aparecem (essas ações são exclusivas da Alfa)

### Segurança
- Backend bloqueia automaticamente qualquer tentativa de admin_revenda acessar dados de outras revendas (filtragem por revendaId no token JWT)

## AlfaMobi — 23/04/2026 — Permissões por perfil: porteiro, recepcionista e operador

### Novidades
- Cada perfil dentro do cliente agora vê apenas os módulos e ações que faz sentido pra função:
  - **Gestor do cliente**: tudo (cadastros completos, dashboard, portaria)
  - **Recepcionista** e **Operador**: cadastram Pessoas, consultam Locais e Horários (sem editar). Sem Dispositivos, sem Perfis de Acesso, sem Dashboard
  - **Porteiro**: consulta Pessoas e Locais (somente leitura, sem botão de editar). Sem Horários, sem Dispositivos, sem Perfis de Acesso, sem Dashboard. Continua com a Portaria ao vivo cheia
- Botões de "Editar", "Excluir", "Adicionar" e "Gerenciar perfis" só aparecem pra quem realmente pode usar — porteiro tocando numa Pessoa abre a ficha somente leitura, sem botão de mexer
- Tela de Cadastros mostra empty state amigável quando o perfil não tem nenhum módulo administrativo disponível

### Segurança
- Mesmo se algum botão escapar (versão antiga do app, deep link), o servidor agora rejeita a operação com mensagem "Acesso negado". A regra é forçada nas duas pontas

## AlfaMobi — 23/04/2026 — Portaria ao vivo + registro manual

### Novidades
- Nova tela **Portaria ao vivo** disponível na Home para porteiros, recepcionistas, gestores do cliente e operadores. Aparece como um cartão grande logo abaixo de "Acessos liberados"
- A tela mostra os **15 últimos acessos em tempo real** (atualiza sozinho a cada 5 segundos), com foto da pessoa, nome, dispositivo onde passou, sentido (entrada/saída) e há quanto tempo aconteceu. Cada item ganha selo colorido: verde para "Permitido", vermelho para "Negado", cinza para "Não identificado"
- Permite **registrar entrada, saída ou negação manualmente** quando o leitor biométrico falha: basta selecionar o local de acesso no topo, buscar a pessoa pelo nome e tocar no botão correspondente. O evento aparece no feed em segundos
- O cartão da portaria não aparece para moradores nem para super_admin — só para quem realmente trabalha na recepção

## AlfaMobi — 23/04/2026 — Super Admin: Usuários (cadastro completo)

### Novidades
- O tile "Usuários" do painel SaaS deixa de ser "em breve" — com isso, o painel SaaS agora tem todos os oito módulos funcionando no app (Revendas, Clientes, Licenças, Usuários, Backup, Manutenção, Planos, Documentação)
- Lista de usuários com busca por nome ou e-mail, filtros rápidos por perfil (Todos / Super / Revenda / Gestor / Operador / Porteiro), avatar com iniciais, selo colorido de perfil (Super Admin/User em roxo, Admin Revenda, Gestor, Operacional em cinza, Morador em verde) e selo de status Ativo/Inativo
- Formulário completo de usuário: nome, e-mail, senha (mínimo 6 caracteres; em edição, deixar em branco mantém a senha atual), perfil, status, revenda e cliente (aparecem conforme o perfil escolhido — admin de revenda precisa de revenda; gestor/operacional precisa de revenda + cliente)
- Excluir usuário disponível no menu de três pontos em edição, com confirmação de que o acesso ao sistema é perdido imediatamente
- Mensagens de erro do servidor aparecem inline no campo certo (por exemplo, "e-mail já cadastrado" destaca o campo)

## AlfaMobi — 23/04/2026 — Super Admin: Documentação do sistema in-app

### Novidades
- O tile "Documentação" do painel SaaS deixa de ser "em breve". Ao abrir, mostra a documentação completa do AlfaControl dentro do app, com a mesma sidebar de tópicos (Dashboard, Clientes, Pessoas, Dispositivos, Backup, etc.) disponível no sistema web
- A documentação fica sempre atualizada automaticamente — qualquer ajuste feito pela equipe Alfa no sistema web aparece imediatamente no app, sem precisar atualizar a versão do AlfaMobi
- Tema da documentação acompanha o tema do seu iPhone (se o aparelho estiver em modo escuro, a doc aparece escura; se estiver claro, aparece clara)
- Botão de recarregar no topo e tela de erro com "Tentar novamente" caso o aparelho esteja sem conexão

## AlfaMobi — 23/04/2026 — Super Admin: Tenants (aba dentro de Planos)

### Novidades
- A tela "Planos" agora tem uma segunda aba chamada "Tenants" (mesma visão que existe no painel web do AlfaControl)
- A aba lista cada revenda cadastrada como um tenant, mostrando nome, CNPJ, e-mail, plano vinculado, preço mensal, status colorido (Trial / Ativa / Vencida), data de término do trial ou próximo vencimento, e uso atual de clientes e usuários em relação aos limites do plano
- Filtros rápidos no topo por status (Todas / Trial / Ativas / Vencidas) e pull-to-refresh
- Revendas legadas que ainda não possuem assinatura vinculada aparecem como "Sem assinatura vinculada" — não ficam invisíveis, como antes

## AlfaMobi — 23/04/2026 — Super Admin: Planos SaaS (cadastro completo)

### Novidades
- O tile "Planos" do painel SaaS deixa de ser "em breve". Ao abrir, mostra duas abas: "Planos" (funcional) e "Assinaturas" (disponível em breve)
- A aba "Planos" lista todos os planos cadastrados (ativos e inativos), com preço mensal e selo de status em cada cartão. Um botão de "+" abre o formulário para criar um plano novo
- Formulário completo de plano: nome, slug (minúsculo, sem espaços), preço mensal obrigatório, preço anual opcional, limites de clientes/usuários/dispositivos (deixar em branco = ilimitado), bloco "Features" em JSON com validação, e interruptor "Ativo" para ocultar o plano sem apagá-lo
- Tocar num plano da lista abre o mesmo formulário em modo edição. Menu de três pontos inclui "Inativar plano" com confirmação explicando que clientes já vinculados continuam usando normalmente
- Mensagens de erro do servidor aparecem inline no campo certo (por exemplo, "slug já em uso" destaca o campo Slug)

## AlfaMobi — 23/04/2026 — Super Admin: Manutenção do sistema + sessão expirada

### Novidades
- O tile "Manutencao" do painel SaaS deixa de ser "em breve". Ao abrir, mostra o status atual (Em manutenção, Programada ou Sistema disponível) com ícone e cor, além da mensagem e da janela programada quando houver
- Permite ativar o modo manutenção imediatamente (com confirmação forte, já que bloqueia todos os tenants), desativar quando estiver ligado, ou só salvar alterações de título, mensagem e janela sem mudar o estado
- Janela de manutenção é opcional: dá pra escolher início e fim via seletores de data e hora, ou deixar em branco para ativação manual

### Melhorias
- Quando a sessão expira, o app agora leva direto pra tela de login em vez de mostrar "tentar novamente" em telas internas como o Dashboard. Ao voltar, basta entrar de novo e continuar de onde estava

## AlfaMobi — 22/04/2026 — Super Admin: disparar backup direto do celular

### Novidades
- A tela de Backup ganhou a seção "Disparar backup" com duas ações: "Backup global" (disponível para Super Admin) e "Backup de cliente"
- "Backup de cliente" abre um seletor com busca por nome para escolher o cliente; ao confirmar, agenda o backup e atualiza o status
- Cada ação mostra uma confirmação explicando que a execução é agendada e pode levar alguns minutos até o servidor processar. Depois de disparar, um aviso confirma e o status é atualizado automaticamente

## AlfaMobi — 22/04/2026 — Super Admin: Backups disponíveis e restauração

### Novidades
- O tile "Backup" do painel SaaS deixa de ser "em breve". Ao abrir, mostra o status atual do serviço de backup com ícone e cor (Aguardando, Em andamento, Concluído, Erro, Ocioso) e a última atualização
- Lista todos os backups já realizados com nome do cliente, data, tamanho (KB/MB/GB) e selo "MinIO" quando o backup inclui as fotos
- Cada backup tem um botão "Restaurar" que, após uma confirmação forte (avisando que dados inseridos depois da data do backup serão perdidos), agenda a restauração daquele cliente. Aparece um aviso e o status atualiza em seguida
- Tela tem botão de atualizar no topo e suporte a pull-to-refresh

## AlfaMobi — 22/04/2026 — Dark theme: ajustes finais (fecha a feature)

### Melhorias
- Dark theme recebe os últimos retoques: botão de voltar e caixa "Lembrar meus dados" no login, além dos ícones e textos da tela "Onde posso acessar" (estados vazio, erro e linhas de detalhe dos cartões), agora respeitam o tema escuro
- Com isso, a feature de tema escuro está completa e cobre todas as telas principais do app

## AlfaMobi — 22/04/2026 — Dark theme: login, QR e outras telas adaptadas

### Melhorias
- Tela de login (seleção de sistema e formulário) agora respeita o tema escuro: fundo, textos e tiles ficam com as cores do modo selecionado
- Telas "Onde posso acessar", cadastro de Pessoa e outras pontuais também passam a seguir o tema
- QR code do visitante mantém sempre fundo branco com módulos pretos — garante que o leitor da portaria funcione mesmo quando o app está no modo escuro

## AlfaMobi — 22/04/2026 — Super Admin: licenças ativas, renovação e histórico

### Novidades
- A aba "Ativas" de Licenças deixa de ser "em breve" e passa a listar todas as licenças ativas no celular, com um selo colorido indicando quantos dias faltam: verde (mais de 15), laranja (entre 8 e 15), vermelho (até 7), cinza para vencida
- Cada licença ativa mostra tipo (mensal/anual), validade, limites de usuários e dispositivos e valor, com botão "Renovar" direto no cartão
- Nova tela de renovação: licença atual destacada no topo (com o selo de dias restantes) e formulário pré-preenchido; escolher um plano preenche o valor automaticamente, e trocar o tipo recalcula
- No detalhe do cliente, nova seção "Licenças" com o botão "Histórico", que abre a lista completa de licenças emitidas para aquele cliente, com status colorido (Ativa / Vencida / Cancelada / Renovada), vigência, valor e quem liberou

## AlfaMobi — 22/04/2026 — Tema escuro (dark mode)

### Novidades
- O app agora tem tema escuro. No Menu, nova seção "Tema" com três opções: Sistema (segue a configuração do aparelho), Claro e Escuro. A escolha é lembrada entre aberturas do app
- Paleta escura pensada para reduzir cansaço visual à noite, com as cores da marca ajustadas para manter contraste e legibilidade

## AlfaMobi — 22/04/2026 — Nova identidade: splash, ícone e nome do app

### Melhorias
- Tela de abertura (splash) e ícone do app no celular atualizados para a nova identidade visual AlfaMobi
- Nome do app nos celulares mudou de "AlfaSync" para "AlfaMobi"
- Na tela de login, as logos ALFAGYM e ALFACONTROL agora aparecem com o mesmo tamanho visual ao abrir o formulário
- Subtítulo do AlfaControl na seleção de sistemas foi ajustado para "Controle de acesso e gestão de pessoas.", refletindo que o sistema atende condomínio, clínica, empresa, academia e outros segmentos
- Tom do texto principal do login suavizado para ficar menos carregado

## AlfaMobi — 22/04/2026 — Ícone AlfaControl na tela de login

### Melhorias
- O ícone genérico ao lado da logo AlfaControl foi substituído pela imagem oficial do produto

## AlfaMobi — 22/04/2026 — Logo AlfaControl na tela de login

### Melhorias
- O nome "AlfaControl" na tela de login foi substituído pela logo oficial do produto

## AlfaMobi — 22/04/2026 — Novo logo na tela de login

### Melhorias
- Logo da tela de login atualizado para a nova identidade visual AlfaMobi

## AlfaMobi — 22/04/2026 — Nova tela de login

### Melhorias
- A tela de login foi redesenhada com um fluxo em duas etapas: primeiro voce escolhe o sistema (AlfaGym ou AlfaControl), depois preenche seu e-mail e senha
- Cada sistema tem seu cartao proprio com icone, nome em destaque e descricao — toque para selecionar e ja ir direto ao login
- Na tela de login, os campos de e-mail e senha ganham icones visuais e um botao de olho para mostrar/ocultar a senha
- Novo rodape "Fale com o administrador" para quem ainda nao tem acesso ao app
- Design modernizado com fundo animado e cores do sistema selecionado

## AlfaMobi — 22/04/2026 — Super Admin: liberar licenca de cliente pelo celular

### Novidades
- O tile "Licencas" do painel SaaS saiu do "Em breve". Ao entrar, abre uma tela com duas abas: Pendentes (funcional agora) e Ativas (na proxima atualizacao)
- Aba "Pendentes" lista todos os clientes aguardando licenca com cartoes mostrando revenda, CNPJ, cidade/UF, segmento e um botao "Liberar licenca" por cliente. Pull-to-refresh atualiza a lista
- Ao tocar "Liberar licenca", abre um formulario com o cliente destacado no topo (evita errar o destino) e campos: Plano (dropdown), Tipo (Mensal 30 dias ou Anual 365 dias), Limites (maximo de usuarios e dispositivos — deixar em branco = ilimitado), Valor e Observacoes
- Selecionar um plano preenche o valor automaticamente; trocar de Mensal para Anual recalcula na hora. Voce pode sobrescrever manualmente se precisar
- Ao liberar, um dialogo de sucesso mostra o resumo (tipo, vigencia ate DD/MM/AAAA, dias restantes) com dois botoes: "Ver cliente" (abre ja o detalhe do cliente recem-ativado) ou "Fechar" (volta pra lista)
- Com isso, o Super Admin consegue aprovar um cliente novo no caminho entre reunioes, em menos de 1 minuto, sem abrir notebook

### Seguranca
- Liberar licenca e uma operacao SUPER_ADMIN only, validada pelo contexto correto do cliente e da revenda no servidor
- O servidor rejeita tentativas em cliente ja ativo (status conflict)

## AlfaMobi — 22/04/2026 — Super Admin: AlfaSync do cliente no celular

### Novidades
- A secao AlfaSync do detalhe do cliente agora e reativa: mostra o Agent Client ID (selecionavel + copiar), um botao pra regenerar o UUID (com aviso forte de que invalida as credenciais existentes) e um switch pra ligar/desligar a integracao sem perder as credenciais
- Nova tela "Credenciais — {cliente}" (acessada pelo botao "Gerenciar credenciais" dentro do AlfaSync) lista todas as credenciais API ativas, com usuario em monoespacado, senha com botao de olho pra mostrar/ocultar, e atalhos de copiar
- Botao "Gerar" no canto inferior emite uma credencial nova (username automatico SYNC-{id} e senha XXXX-XXXX-XXXX-XXXX). Se ja existe uma credencial ativa, aparece um aviso explicando que a senha anterior sera invalidada
- Apos gerar, um dialogo exibe usuario + senha em destaque com botoes "Copiar tudo" e "Entendi, ja salvei" — paridade com o web mas com aviso adicional reforcando que a senha continua visivel na lista por conveniencia
- Botao de lixeira em cada credencial revoga imediatamente (aparece confirmacao explicando que o dispositivo perde acesso na hora)

### Melhorias
- O detalhe do cliente perdeu a secao "Tipos de Pessoa" obsoleta — aquela gestao pertence ao painel do proprio cliente (gestor_cliente), nao ao super_admin

### Seguranca
- Toda requisicao que muda o AlfaSync (gerar, revogar, regenerar ID, toggle) e autenticada com o contexto do cliente correto, garantindo que o super_admin nunca afeta um tenant errado
- Revogar credencial e destrutivo e confirmado; regenerar o Agent Client ID mostra aviso extra de que credenciais antigas ficam invalidas

## AlfaMobi — 22/04/2026 — Super Admin: gestao de clientes pelo celular

### Novidades
- O tile "Clientes" do painel SaaS saiu do "Em breve" e agora abre a lista completa de clientes cadastrados, cruzando todas as revendas
- Busca no topo filtra em tempo real; chips de status (Todos / Aguardando / Ativo / Inativo / Congelado) refinam a lista e ajudam a localizar rapidamente; rolagem infinita carrega mais a medida que voce desce
- Tap em qualquer cliente abre o detalhe completo com secoes Identificacao, Contato, Observacoes e Metadados, ja preparadas com espacos (ainda vazios) para AlfaSync e Tipos de Pessoa que chegam em atualizacoes proximas
- Botao "+" da lista abre um formulario completo para cadastrar novo cliente com todos os dados essenciais: nome, segmento (condominio/escola/empresa/clube), documento (CNPJ), contato, endereco, plano solicitado e a revenda a que pertence. Mascaras automaticas para CNPJ e telefone
- Botao "Editar" (lapis) no detalhe abre o mesmo formulario pre-preenchido para ajustar qualquer campo. A revenda fica travada no modo edicao, evitando transferencia acidental entre revendas
- Menu de 3 pontinhos no detalhe tem "Mudar status" (aplica so o status sem mexer nos demais campos) e "Excluir cliente" (com aviso explicando que pessoas, veiculos, locais, autorizacoes e eventos vinculados tambem sao removidos em cascata)

### Melhorias
- Validacao imediata: campos obrigatorios e erros vindos do servidor (ex.: segmento invalido) aparecem no proprio campo com a mensagem exata

### Seguranca
- Todas as acoes de cliente usam o contexto correto de revenda no servidor (via cabecalho dedicado de revenda), garantindo que o cliente criado sempre fique vinculado ao tenant certo
- Exclusao destrutiva de cliente passa por confirmacao com aviso explicito das consequencias (cascata em registros vinculados)

## AlfaMobi — 22/04/2026 — Super Admin: provisionar revenda com trial de 14 dias

### Novidades
- Botao "+" da lista de revendas agora abre um menu rapido com duas opcoes: "Cadastro completo" (formulario com todos os campos que ja existia) e "Provisionar trial" (novo fluxo rapido)
- "Provisionar trial" cria a revenda, o usuario administrador e a assinatura de trial de 14 dias em uma unica operacao atomica — enxuto, so os campos essenciais (nome da revenda, admin, senha e contatos opcionais)
- Apos provisionar, aparece um dialogo de confirmacao com o resumo da operacao (revenda criada, data de fim do trial no formato DD/MM/AAAA e e-mail do admin) e dois botoes: "Fechar" volta para a lista, "Ver revenda" abre ja o detalhe da nova revenda
- Com isso, o Super Admin consegue cadastrar um novo cliente revendedor no app do zero ao produtivo em menos de um minuto, direto do celular

### Seguranca
- A senha do admin continua validada com minimo de 8 caracteres tanto no celular quanto no servidor
- A operacao inteira passa pelos mesmos controles de acesso do painel web (so Super Admin pode provisionar)

## AlfaMobile — 22/04/2026 — Super Admin: criar e editar revenda no app

### Novidades
- Botao "Nova" no canto inferior direito da lista de revendas agora abre um formulario completo para cadastrar uma revenda diretamente pelo celular — com secoes separadas para Empresa, Contatos, Adicionais e Acesso da revenda
- Detalhe da revenda ganhou botao "Editar" (icone de lapis) no canto superior, que abre o mesmo formulario com tudo preenchido para ajustar qualquer campo
- Mascara automatica no CNPJ (00.000.000/0000-00) e nos telefones de Administrativo/Comercial/Suporte — fica formatado enquanto voce digita
- Upload de logo: toque em "Anexar" para escolher da galeria e ver um preview imediato; "Remover" se quiser tirar a imagem
- Na secao "Acesso da revenda", voce pode criar ou atualizar o admin junto com o cadastro — nome, e-mail e senha (minimo 8 caracteres). No modo editar, deixar os campos em branco significa "nao alterar o admin"; trocar so a senha tambem funciona

### Melhorias
- Validacao imediata: campos obrigatorios e e-mails/CNPJs duplicados sao destacados no proprio campo com a mensagem exata vinda do servidor — fim do "Erro generico"

### Seguranca
- O cadastro do admin continua valendo como no web: e-mail unico em toda a plataforma, senha com minimo de 8 caracteres, e a operacao so fica disponivel para Super Admin

## AlfaMobile — 22/04/2026 — Super Admin: lista de revendas no app

### Novidades
- O tile "Revendas" do painel SaaS saiu do "Em breve" e agora abre a lista completa de revendas cadastradas
- A lista tem busca por nome/CNPJ, rolagem infinita, pull-to-refresh e indicador de status (Ativo/Inativo) em cada cartao
- Ao tocar numa revenda, abre o detalhe com as secoes Empresa (nome fantasia, CNPJ formatado, razao social, site, status e trial), Contatos (administrativo, comercial e suporte — cada um com nome, telefone e e-mail), Adicionais (observacao) e Admin da revenda (nome, e-mail e status do usuario vinculado)
- No menu (3 pontinhos) do detalhe, duas acoes cobertas: "Resetar senha do admin" — abre um dialogo com a nova senha (minimo 8 caracteres) e aplica imediatamente; e "Excluir revenda" — com confirmacao e aviso de clientes ativos

### Seguranca
- Todas as acoes so aparecem para Super Admin; a excluir e a reset-senha passam por confirmacao antes de executar

## AlfaMobile — 22/04/2026 — Super Admin no app com painel SaaS

### Novidades
- Super Admin agora entra no app e cai direto em um painel proprio com tres abas: Dashboard, SaaS e Menu
- O Dashboard traz 17 indicadores do negocio em tempo real — Receita (MRR, ARR, MRR de Licencas), Tenants (ativos, em trial, atrasados, suspensos e cancelados), Clientes & Licencas (ativos, aguardando licenca, licencas ativas, vencendo em 7 dias) e Indicadores (Churn mensal, ARPU, LTV). Pull-to-refresh e botao de atualizar no topo mantem os numeros sempre em dia
- O hub SaaS ja traz oito areas de gestao pre-organizadas (Revendas, Clientes, Licencas, Usuarios, Backup, Manutencao, Planos e Documentacao) marcadas como "Em breve" — cada uma sera liberada em uma proxima atualizacao

## AlfaMobile — 21/04/2026 — Push no celular quando voce mesmo passa no leitor

### Novidades
- Agora voce recebe uma notificacao push no celular sempre que voce passa no leitor, com o nome do dispositivo e o resultado (permitido/negado). Tambem aparece um item novo no sininho com o titulo "Seu acesso"
- Funciona tanto em condominio quanto em escola, empresa e clube

### Correcoes
- O registro do celular para receber push estava bloqueado para quem tem perfil de morador — agora a Pessoa logada registra o aparelho normalmente ao abrir o app

### Seguranca
- O push so chega na conta que passou no leitor; outras pessoas do mesmo condominio nao recebem nada
- Se voce ainda nao trocou a senha inicial do app, o push nao e' enviado ate voce ativar a conta
- A preferencia "Notificar acessos" tambem vale aqui: se voce desligar, o push do proprio acesso para de chegar

## AlfaMobile — 21/04/2026 — Nova tela "Onde posso acessar"

### Novidades
- Novo atalho "Onde posso acessar" na Home (icone de escudo), logo apos Encomendas. Toque para ver todos os leitores/ambientes que voce esta autorizado a usar agora, sem precisar testar na vida real ou ligar pro gestor
- Cada item mostra: nome do dispositivo, horario em que o acesso vale (ex.: "Comercial (08:00 - 18:00)" ou "Qualquer horario" quando nao ha restricao), dias da semana ("Todos os dias", "Seg a Sex", "Fim de semana" ou os dias especificos) e qual perfil libera esse acesso
- Disponivel em condominio, escola, empresa e clube. Pull-to-refresh e botao de atualizar no topo mantem a lista sempre em dia

### Melhorias
- Quando voce ainda nao tem nenhum perfil de acesso, a tela mostra uma mensagem clara orientando a procurar o responsavel do seu local — fim da adivinhacao sobre "eu posso passar aqui ou nao?"

## AlfaMobile — 21/04/2026 — Home personalizada pelo tipo do seu ambiente

### Novidades
- A Home agora se adapta ao tipo do seu ambiente: em escola, empresa e clube, os atalhos de "QR Visitante" e "Encomendas" (que so fazem sentido em condominio) nao aparecem mais; sobram os atalhos realmente uteis — Eventos e Horarios
- O seu tipo (Aluno, Colaborador, Morador etc.) agora aparece como selo abaixo do seu nome, para identificar rapido o seu perfil

### Melhorias
- A secao "Ultimos acessos" ficou mais clara quando nao ha registros: em vez de uma mensagem generica, agora explica que eventos aparecem ali depois que voce passa por um leitor cadastrado, e orienta a falar com o responsavel caso algo pareca diferente

## AlfaMobile — 21/04/2026 — Push no celular quando o dependente passa no leitor

### Novidades
- Voce agora recebe uma notificacao push no celular sempre que um dependente vinculado a voce passa no leitor — com o nome de quem passou, o dispositivo e o resultado (permitido/negado)
- Pai e mae vinculados ao mesmo filho recebem o push, cada um no seu aparelho

### Seguranca
- A notificacao chega apenas para quem esta diretamente vinculado como responsavel; quem nao tem vinculo nao recebe nada
- Se o responsavel ainda nao trocou a senha inicial do app, o push nao e' enviado ate ele ativar a conta

## AlfaMobile — 21/04/2026 — Dependentes: veja os acessos de quem voce e' responsavel

### Novidades
- O gestor pode vincular dependentes a uma Pessoa direto no cadastro (ex.: pai/mae vinculados ao filho). A Pessoa logada no app passa a enxergar tambem os eventos dos dependentes, alem dos proprios
- Na tela "Eventos", quando houver dependentes vinculados, aparece uma nova linha de chips "Todos · Eu · {nome do dependente}" para filtrar rapidamente
- Na Home, nos ultimos 3 eventos, o nome da pessoa aparece em destaque quando o evento for de um dependente (facil identificar quem passou)

### Seguranca
- Cada Pessoa so enxerga os proprios eventos + os dos dependentes diretamente vinculados a ela. Quem nao e' responsavel nao tem acesso

## AlfaMobile — 21/04/2026 — Botao "Esqueci minha senha" explica recuperacao

### Melhorias
- O botao "Esqueci minha senha" na tela de login deixou de ser inativo: ao tocar, abre um aviso explicando que o responsavel do condominio (ou da academia) cadastra uma nova senha, e a Pessoa troca ela no proximo acesso ao app

## AlfaMobile — 21/04/2026 — Morador ve seus proprios acessos

### Novidades
- A Home do morador passa a mostrar saudacao + os ultimos 3 eventos dele, com um botao "Ver todos" que abre a lista completa
- A tela "Eventos" foi liberada para o morador — mostra somente os acessos da propria pessoa (nunca de terceiros)

### Seguranca
- Moradores so enxergam os proprios eventos; dados de outras pessoas do mesmo condominio nao aparecem em nenhuma rota do app

## AlfaMobile — 21/04/2026 — Moradores ja conseguem logar no app

### Novidades
- Moradores cadastrados com a opcao "terá login" passam a entrar normalmente no app usando o e-mail e a senha inicial entregues pelo gestor
- No primeiro acesso o app abre automaticamente a tela "Defina sua senha" — o morador escolhe a propria senha (minimo 6 caracteres) e segue direto para a Home

### Seguranca
- A senha inicial e' obrigatoria na troca no primeiro login, garantindo que apenas o morador saiba a senha definitiva

## AlfaMobile — 20/04/2026 — Foto do cadastro + atalho do evento para a pessoa

### Novidades
- No detalhe do evento, novo botão "Ver cadastro da pessoa" abre direto o cadastro da pessoa identificada

### Correções
- As fotos das pessoas agora aparecem também no cadastro (lista de Pessoas e tela de detalhe)

## AlfaMobile — 20/04/2026 — Filtro por resultado na tela Eventos

### Novidades
- Nova linha de chips na tela "Eventos" para filtrar a lista por resultado: Todos, Permitido, Negado ou Não identificado

## AlfaMobile — 20/04/2026 — Detalhe do evento + fotos e correções na lista

### Novidades
- Tocar em qualquer evento na tela "Eventos" abre uma nova tela de detalhe com foto grande, nome, documento, dispositivo, identificação, data e hora completa, e motivo (quando houver)

### Correções
- As fotos das pessoas agora aparecem nos cartões da lista de Eventos e no detalhe
- Eventos de pessoas não identificadas deixam de aparecer como "Digital" (ou outro método) e passam a mostrar "Não identificado" na linha de identificação

### Melhorias
- No detalhe do evento, a linha "Sentido do leitor" só aparece quando o leitor estiver configurado

## AlfaMobile — 20/04/2026 — Entrada e saída reais na Home + sentido dos leitores

### Novidades
- Home do gestor agora mostra os horários reais da última entrada e da última saída, quando os leitores estão configurados com o sentido correto
- Cadastro de Dispositivo ganhou a opção "Sentido do leitor" (Entrada, Saída, Ambos ou Não configurado) para identificar o tipo de passagem

### Melhorias
- Se nenhum leitor do cliente estiver configurado com sentido, os cartões "Acessos liberados" são automaticamente ocultos em vez de mostrar dados em branco
- A tela de detalhe do Dispositivo exibe o sentido configurado

## AlfaMobile — 20/04/2026 — Tela de Eventos e novo menu rápido

### Novidades
- Nova tela "Eventos" com os acessos dos leitores em tempo real: foto, nome, dispositivo, data/hora e situação (Permitido, Negado ou Não identificado)
- Campo de busca por nome e filtro por dispositivo
- Rolagem carrega mais registros automaticamente; puxar para baixo atualiza a lista

### Melhorias
- Atalhos de módulos no Home redesenhados como cartões maiores em grade 2x2, no mesmo estilo da tela de Cadastros

## AlfaMobile — 20/04/2026 — Dispositivos liberados por Perfil de Acesso

### Novidades
- No detalhe de cada Perfil de Acesso, nova seção "Dispositivos liberados" com lista dos dispositivos vinculados e o horário (ou "Qualquer horário")
- Botão "Gerenciar" abre tela dedicada para adicionar ou remover dispositivos do perfil, escolhendo opcionalmente um horário específico
- Trocar o horário de um dispositivo já vinculado é instantâneo: basta adicionar de novo o mesmo dispositivo com o novo horário

## AlfaMobile — 20/04/2026 — Dispositivos na tela de Cadastros

### Novidades
- Nova tela "Dispositivos" no app para cadastrar leitores ControlID (iDFace, iDBlock e iDUX), com nome, IP, porta e credenciais de acesso
- Status Online/Offline de cada dispositivo visível tanto na lista quanto no detalhe

### Melhorias
- O tile "Dispositivos" no hub de Cadastros deixou de exibir "Em breve" e passou a abrir a nova tela
