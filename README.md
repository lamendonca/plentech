# Projeto Plentech - Integrações UpVendas e B4U
Este repositório contém as integrações desenvolvidas em **AdvPL/Protheus** para comunicação via serviços **RESTful** entre os sistemas **UpVendas** e **B4U**.

---
## 📂 Estrutura do Projeto

```

src/

 ├─ assets/

 │   ├─ libPlentech.prw        # Biblioteca de funções auxiliares comuns

 │   ├─ b4you/                 # Projeto B4U

 │   │   ├─ b4you.prw

 │   │   ├─ GERA_DANFE.prw

 │   │   ├─ PLXMLNOTA.prw

 │   │   └─ restB4U.prw        # Serviços REST B4U

 │   └─ upVendas/              # Projeto UpVendas

 │       ├─ upCustomer.prw     # Endpoints de Clientes

 │       ├─ upOrder.prw        # Endpoints de Pedidos

 │       ├─ upProducts.prw     # Endpoints de Produtos

 │       └─ upVendas.prw       # Declaração do WSRESTFUL

 └─ bin/

     └─ b4uSchedule.prw        # Rotinas de agendamento (B4U)

```


---

## 🚀 Serviços REST Disponíveis

### 🔹 Projeto **UpVendas** (`upVendas.prw`)

#### **1. Consultar Cliente**


* **Endpoint:** `GET /upVendas/Consultas/Cliente/{CNPJ}`

* **Request:**
  

```json

{

  "CNPJ": "00.000.000/0001-91"

}

```

* **Response (200):**

```json

{

  "CODIGO": "000123",

  "LOJA": "01",

  "NOME": "Cliente Exemplo Ltda",

  "FANTASIA": "Cliente Exemplo",

  "CGC": "00.000.000/0001-91"

}

```

* **Status possíveis:** `200 OK`, `404 Not Found`, `500 Internal Error`

---

#### **2. Consultar Produto**


* **Endpoint:** `GET /upVendas/Consultas/Produto/{Product}`

* **Request:**

  

```json

{

  "Product": "CODIGO"

}

```

  
* **Response (200):**

  

```json

{

  "CodigoReferencia": "CODIGO",

  "DescricaoProduto": "DESCRICAO",

  "Unidade": "UN",

  "GrupoDeProduto": "GRUPO",

  "Peso": 98,

  "Volume": 1,

  "CodigoDeBarras": "CODIGODEBARRAS",

  "Preco": 5899,

  "Estoque": 10

}

```

  

* **Status possíveis:** `200 OK`, `404 Not Found`

  

---

  

#### **3. Consultar Todos os Produtos**

  

* **Endpoint:** `GET /upVendas/Consultas/Produtos`

* **Response (200):**

  

```json

[

  {

    "CodigoReferencia": "CODIGO",

    "DescricaoProduto": "DESCRICAO",

    "Unidade": "UN",

    "GrupoDeProduto": "GRUPO",

    "Peso": 98,

    "Volume": 1,

    "CodigoDeBarras": "CODIGODEBARRAS",

    "Preco": 5899,

    "Estoque": 10

  },

  {

    "CodigoReferencia": "CODIGO",

    "DescricaoProduto": "DESCRICAO",

    "Unidade": "UN",

    "GrupoDeProduto": "GRUPO",

    "Peso": 98,

    "Volume": 1,

    "CodigoDeBarras": "CODIGODEBARRAS",

    "Preco": 5899,

    "Estoque": 10

  }

]

```

  

---

  

#### **4. Incluir Cliente**

  

* **Endpoint:** `POST /upVendas/Incluir/Cliente`

* **Request:**

  

```json

{

  "CodigoCliente": "123456",

  "NomeCliente": "Novo Cliente Ltda",

  "EnderecoCliente": "Rua Exemplo, 123",

  "MunicipioCliente": "São Paulo",

  "EstadoCliente": "SP",

  "CnpjCpfCliente": "11.111.111/0001-11",

  "IeCliente": "ISENTO",

  "CepCliente": "01001-000"

}

```

  

* **Response (200):**

  

```json

{

  "mensagem": "Cliente incluído com sucesso"

}

```

  

---

  

#### **5. Incluir Pedido de Venda**

  

* **Endpoint:** `POST /upVendas/INCLUIR/PedidoVenda`

* **Request:**

  

```json

{

  "filial": "01",

  "cabecalho": [

    { "NumeroPedido": "12345", "CodigoCliente": "123456" }

  ],

  "itens": [

    {

      "CodigoProduto": "CODIGO",

      "QtdVendida": 1,

      "PrecoVenda": 5899

    }

  ],
  "pagamento": [

    {

      "forma": "R$",

      "QtdVendida": 100,
      
      "Parcelas": 1

    }

  ]

}

```

  

* **Response (200):**

  

```json

{

  "mensagem": "Pedido incluído com sucesso",

  "NumeroPedido": "12345"

}

```

  

* **Status possíveis:** `200 OK`, `400 Bad Request`

  

---

  

### 🔹 Projeto **B4U** (`restB4U.prw`)

  

#### **1. Emitir Nota Fiscal (DANFE)**

  

* **Endpoint:** `POST /b4u/EmitirDanfe`

* **Request:**

  

```json

{

  "NumeroNota": "123456",

  "Serie": "1",

  "Filial": "01"

}

```

  

* **Response (200):**

  

```json

{

  "mensagem": "DANFE gerada com sucesso",

  "caminhoArquivo": "notabase64"

}

```

  

---

  

#### **2. Consultar XML de Nota**

  

* **Endpoint:** `GET /b4u/XmlNota/{NumeroNota}`

* **Response (200):**

  

```json

{

  "NumeroNota": "123456",

  "Xml": "<xml>...</xml>"

}

```

  

---
## 📌 Observações

* Todos os endpoints retornam JSON.

* É recomendado habilitar logs (`RESTLOGREQUEST=1` e `RESTLOGRESPONSE=1`) no `appserver.ini` durante testes.

* Campos e payloads podem variar de acordo com a versão do Protheus e customizações.

---