import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Helper to get current directory in ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Path to service account key (relative to project root)
const serviceAccountPath = join(__dirname, '../defesa-backend/src/main/resources/serviceAccountKey.json');
const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Cities list with short codes (consistent with backend hardcoded list)
const cidades = [
  { codigo: 'ATI', nome: 'Atibaia' },
  { codigo: 'BP',  nome: 'Bragança Paulista' },
  { codigo: 'JOA', nome: 'Joanópolis' },
  { codigo: 'NAZ', nome: 'Nazaré Paulista' },
  { codigo: 'PIR', nome: 'Piracaia' },
  { codigo: 'TUI', nome: 'Tuiuti' },
  { codigo: 'VAR', nome: 'Vargem' }
];

async function upload() {
  console.log('🚀 Iniciando upload de cidades para o Firestore...');
  const collectionRef = db.collection('cidades');

  for (const cidade of cidades) {
    try {
      // Use the code as the document ID for consistency
      await collectionRef.doc(cidade.codigo).set(cidade);
      console.log(`✅ Cidade adicionada: ${cidade.nome} (${cidade.codigo})`);
    } catch (error) {
      console.error(`❌ Erro ao adicionar ${cidade.nome}:`, error);
    }
  }
  console.log('✨ Upload concluído!');
  process.exit(0);
}

upload().catch(err => {
  console.error('💥 Erro fatal no upload:', err);
  process.exit(1);
});
