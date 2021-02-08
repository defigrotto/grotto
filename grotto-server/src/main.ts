import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'debug', 'log', 'verbose'],
  });

  app.enableCors();

  const options = new DocumentBuilder()
    .setTitle('Grotto API')
    .setDescription('API endpoints for Grotto')
    .setVersion('1.0.0')
    .addTag('grotto')
    .addApiKey({
      type: 'apiKey', // this should be apiKey
      name: 'api-key', // this is the name of the key you expect in header
      in: 'header',
    }, 'api-key')
    .build();

  const document = SwaggerModule.createDocument(app, options);
  SwaggerModule.setup('swagger', app, document);

  await app.listen(process.env.PORT);

}
bootstrap();
