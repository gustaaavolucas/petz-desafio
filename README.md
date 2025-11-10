# Desafio Petz + ArgoCD

Este repositório demonstra um pipeline **completo** de entrega contínua usando:

- **Aplicação containerizada** (Go, “Hello World”);
- **Docker Hub** como registry;
- **Kubernetes local com Minikube**;
- **Provisionamento com Terraform** (namespaces + ArgoCD via Helm);
- **ArgoCD** fazendo GitOps;
- **Ingress** no Minikube para acessar **app** e **ArgoCD** via browser;
- **GitHub Actions** buildando a imagem e atualizando o YAML automaticamente.

A ideia é: **deu push → GitHub Actions builda e sobe imagem → atualiza manifest → ArgoCD aplica no cluster → você acessa no navegador.**

---

## 1. Pré-requisitos

Instale na sua máquina:

1. **Docker** (rodando e com acesso ao Docker Hub)
2. **kubectl**
3. **minikube**
4. **terraform**Desafio CI/CD Kubernetes + ArgoCD

Este repositório demonstra um pipeline completo de entrega contínua usando:

Aplicação containerizada (Go, “Hello World”);

Docker Hub como registry;

Kubernetes local com Minikube;

Provisionamento com Terraform (namespaces + ArgoCD via Helm);

ArgoCD fazendo GitOps;

Ingress no Minikube para acessar app e ArgoCD via browser;

GitHub Actions buildando a imagem e atualizando o YAML automaticamente.

A ideia é: deu push → GitHub Actions builda e sobe imagem → atualiza manifest → ArgoCD aplica no cluster → você acessa no navegador.

1. Pré-requisitos

Instale na sua máquina:

Docker (rodando e com acesso ao Docker Hub)

kubectl

minikube

terraform

git

💡 Testes rápidos:

docker --version
kubectl version --client
minikube version
terraform version

2. Clonar o projeto
git clone git@github.com:gustaaavolucas/petz-desafio.git
cd petz-desafio


(se quiser usar https: https://github.com/gustaaavolucas/petz-desafio.git)

3. Subir o Kubernetes (Minikube)

Vamos usar o driver docker:

minikube start --driver=docker


Conferir:

kubectl get nodes


Tem que aparecer o nó do minikube.

4. Habilitar o Ingress do Minikube

Vamos expor a aplicação e o ArgoCD via hostname:

minikube addons enable ingress
kubectl get pods -n ingress-nginx


Espere o ingress-nginx-controller ficar Running.

5. Estrutura do projeto
.
├── app/                  # aplicação Go (Hello World)
│   ├── main.go
│   └── Dockerfile
├── infra/                # terraform: namespaces + argocd via helm
│   ├── providers.tf
│   ├── main.tf
│   └── modules/
│       ├── k8s-base/     # cria namespace apps
│       └── argocd/       # instala argo-cd
├── k8s/                  # manifests kubernetes da aplicação
│   ├── app-deployment.yaml
│   ├── app-service.yaml
│   ├── app-ingress.yaml
│   └── argocd-ingress.yaml
├── argocd/
│   └── app.yaml          # Application do ArgoCD apontando pro repo
└── .github/workflows/
    └── ci-cd.yaml        # pipeline do GitHub Actions

6. Subir a infra com Terraform

Entre na pasta de infra:

cd infra
terraform init
terraform plan
terraform apply -auto-approve
cd ..


O que isso faz:

cria namespace apps

cria namespace argocd

instala ArgoCD no namespace argocd via Helm

já instala o ArgoCD com:

1 réplica

--insecure

service ClusterIP (vamos acessar via ingress)

Conferir:

kubectl get pods -n argocd


Tem que aparecer algo como argocd-server-xxxx Running.

7. Buildar e enviar a imagem da aplicação

A aplicação está em app/main.go.
O Deployment está configurado para usar seu Docker Hub: docker.io/uz2idkfwxm/hello-cicd:latest.

Então precisa existir essa imagem no Docker Hub:

cd app
docker build -t docker.io/uz2idkfwxm/hello-cicd:latest .
docker push docker.io/uz2idkfwxm/hello-cicd:latest
cd ..


Se usar outro usuário do Docker Hub, troque o nome da imagem no arquivo:
k8s/app-deployment.yaml

8. Aplicar os manifests da aplicação

Agora vamos criar a app no cluster:

kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml
kubectl apply -f k8s/app-ingress.yaml


Conferir:

kubectl get pods -n apps
kubectl get svc -n apps
kubectl get ingress -n apps


Os pods devem ficar Running.

9. Expor via Ingress (hello.local)

O ingress da app está em k8s/app-ingress.yaml e usa o host:

host: hello.local


Agora pegue o IP do Minikube:

minikube ip


Suponha que veio 192.168.49.2.

Adicione no /etc/hosts:

echo "192.168.49.2 hello.local" | sudo tee -a /etc/hosts


Acesse no navegador:

👉 http://hello.local

Você deve ver algo como:

Desafio Petz

10. Expor o ArgoCD (argocd.local)

Já temos o Ingress do ArgoCD em k8s/argocd-ingress.yaml.

kubectl apply -f k8s/argocd-ingress.yaml
kubectl get ingress -n argocd


Adicionar no /etc/hosts também:

minikube ip   # pega o IP de novo
echo "192.168.49.2 argocd.local" | sudo tee -a /etc/hosts


Acessar:

👉 http://argocd.local

Senha do admin:

kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d


Usuário: admin

11. Conectar o ArgoCD ao repositório

O arquivo argocd/app.yaml já aponta pro seu GitHub:

repoURL: https://github.com/gustaaavolucas/petz-desafio.git
path: k8s
targetRevision: main


Só aplicar:

kubectl apply -f argocd/app.yaml
kubectl get applications -n argocd


Isso cria no ArgoCD o app hello-cicd, que vai ler os manifests de k8s/.

Se no painel aparecer OutOfSync, pode esperar alguns segundos ou clicar em SYNC.

12. GitHub Actions (CI/CD)

O workflow está em .github/workflows/ci-cd.yaml e faz:

roda ao dar push na main;

faz login no Docker Hub;

builda a imagem docker.io/${DOCKERHUB_USERNAME}/hello-cicd:<commit>;

faz sed no k8s/app-deployment.yaml trocando a tag;

faz git pull --rebase origin main;

faz git commit e git push;

ArgoCD enxerga o novo commit e atualiza o cluster.

12.1. Secrets necessários no GitHub

No repositório → Settings → Secrets and variables → Actions:

DOCKERHUB_USERNAME = uz2idkfwxm

DOCKERHUB_TOKEN = token criado no Docker Hub (Settings → Security → New Access Token)

Depois disso, basta dar push e o pipeline roda sozinho.

13. Fluxo de desenvolvimento (como testar uma mudança)

edite app/main.go (mude o texto);

builda e faz push:

docker build -t docker.io/uz2idkfwxm/hello-cicd:latest ./app
docker push docker.io/uz2idkfwxm/hello-cicd:latest


(opcional) atualize a imagem no k8s/app-deployment.yaml se quiser usar uma tag específica;

git add .

git commit -m "feat: altera mensagem"

git push

veja no ArgoCD (http://argocd.local) o app sincronizar

acesse http://hello.local
 e veja a nova versão.

14. Comandos úteis

Ver tudo que tem no namespace da aplicação:

kubectl get all -n apps


Ver status do ArgoCD:

kubectl get pods -n argocd


Reiniciar o deployment da app:

kubectl rollout restart deployment/hello-cicd -n apps


Ver logs da app:

kubectl logs -n apps -l app=hello-cicd

15. Problemas comuns
15.1. “ImagePullBackOff”

A imagem do Docker Hub não existe ou o nome do usuário está errado no k8s/app-deployment.yaml.
→ buildar e dar push de novo.

15.2. “ERR_TOO_MANY_REDIRECTS” ao acessar o ArgoCD

Isso acontecia porque o ArgoCD queria HTTPS e o Ingress estava em HTTP.
No Terraform já deixamos o ArgoCD com --insecure e o Ingress com:

nginx.ingress.kubernetes.io/ssl-redirect: "false"


Então acessa sempre por http://argocd.local
.

15.3. minikube service não abre

O Service está como ClusterIP, então acesse via Ingress (hello.local).
Se quiser NodePort, mude o Service.

16. O que este projeto mostra

provisionamento de componentes de plataforma com Terraform;

empacotamento de app em Docker;

orquestração em Kubernetes (Deployment, Service, Ingress);

controle declarativo com ArgoCD (GitOps);

esteira de CI/CD no GitHub Actions empurrando imagem e atualizando manifest;

acesso web simples para app e ArgoCD.

> 💡 Testes rápidos:
> ```bash
> docker --version
> kubectl version --client
> minikube version
> terraform version
> ```

---

## 2. Clonar o projeto

```bash
git clone git@github.com:gustaaavolucas/petz-desafio.git
cd petz-desafio
```

(se quiser usar https: `https://github.com/gustaaavolucas/petz-desafio.git`)

---

## 3. Subir o Kubernetes (Minikube)

Vamos usar o driver docker (o que você já usou e funcionou):

```bash
minikube start --driver=docker
```

Conferir:

```bash
kubectl get nodes
```

Tem que aparecer o nó do minikube.

---

## 4. Habilitar o Ingress do Minikube

Vamos expor a aplicação e o ArgoCD via hostname:

```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
```

Espere o `ingress-nginx-controller` ficar `Running`.

---

## 5. Estrutura do projeto

```text
.
├── app/                  # aplicação Go (Hello World)
│   ├── main.go
│   └── Dockerfile
├── infra/                # terraform: namespaces + argocd via helm
│   ├── providers.tf
│   ├── main.tf
│   └── modules/
│       ├── k8s-base/     # cria namespace apps
│       └── argocd/       # instala argo-cd
├── k8s/                  # manifests kubernetes da aplicação
│   ├── app-deployment.yaml
│   ├── app-service.yaml
│   ├── app-ingress.yaml
│   └── argocd-ingress.yaml
├── argocd/
│   └── app.yaml          # Application do ArgoCD apontando pro repo
└── .github/workflows/
    └── ci-cd.yaml        # pipeline do GitHub Actions
```

---

## 6. Subir a infra com Terraform

```bash
cd infra
terraform init
terraform apply -auto-approve
cd ..
```

O que isso faz:
- cria namespace `apps`
- cria namespace `argocd`
- instala **ArgoCD** via Helm (1 réplica, --insecure, service ClusterIP)

Conferir:

```bash
kubectl get pods -n argocd
```

---

## 7. Buildar e enviar a imagem

```bash
cd app
docker build -t docker.io/uz2idkfwxm/hello-cicd:latest .
docker push docker.io/uz2idkfwxm/hello-cicd:latest
cd ..
```

---

## 8. Aplicar os manifests

```bash
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml
kubectl apply -f k8s/app-ingress.yaml
```

---

## 9. Adicionar no /etc/hosts

```bash
minikube ip
echo "192.168.49.2 hello.local" | sudo tee -a /etc/hosts
```

Acessar: http://hello.local

---

## 10. Acessar o ArgoCD

```bash
kubectl apply -f k8s/argocd-ingress.yaml
minikube ip
echo "192.168.49.2 argocd.local" | sudo tee -a /etc/hosts
```

Acessar: http://argocd.local

Senha:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

Usuário: admin

---

## 11. Criar o app no ArgoCD

```bash
kubectl apply -f argocd/app.yaml
kubectl get applications -n argocd
```

---

## 12. Pipeline do GitHub Actions

O workflow (`.github/workflows/ci-cd.yaml`) faz:

1. build da imagem
2. push pro Docker Hub
3. atualiza `k8s/app-deployment.yaml`
4. commit e push pro GitHub
5. ArgoCD detecta e aplica automaticamente

Secrets necessários no GitHub:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

---

## 13. Comandos úteis

```bash
kubectl get all -n apps
kubectl get pods -n argocd
kubectl logs -n apps -l app=hello-cicd
kubectl rollout restart deployment/hello-cicd -n apps
```

---

## 14. Demonstração final

- **App:** http://hello.local  
- **ArgoCD:** http://argocd.local
