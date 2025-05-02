import 'dart:convert';
import 'dart:io';

import 'package:avisai4/data/models/registro.dart';
import 'package:flutter/material.dart';

import 'validation_badge.dart';

class RegistroCard extends StatelessWidget {
  final String categoria;
  final String endereco;
  final String data;
  final String imagemUrl;
  final StatusValidacao status; // Modificado de bool para StatusValidacao
  final bool sincronizado;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const RegistroCard({
    super.key,
    required this.categoria,
    required this.endereco,
    required this.data,
    required this.imagemUrl,
    this.status = StatusValidacao.naoValidado, // Valor padrão modificado
    this.sincronizado = true,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem
            SizedBox(
              height: 150.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagem principal
                  _buildImageFromBase64(imagemUrl),

                  // Badges de status
                  Positioned(
                    top: 8.0,
                    right: 8.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ValidationBadge(status: status),
                        if (!sincronizado) ...[
                          const SizedBox(height: 4.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wifi_off,
                                  color: Colors.white,
                                  size: 16.0,
                                ),
                                SizedBox(width: 4.0),
                                Text(
                                  'Não sincronizado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Informações
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoria
                  Text(
                    categoria,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),

                  // Endereço
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16.0,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          endereco,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),

                  // Data
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16.0,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        data,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ações
            if (onDelete != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Adicionar este método à classe
  Widget _buildImageFromBase64(String base64String) {
    try {
      if (base64String.isEmpty) {
        return _buildImagePlaceholder();
      }

      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    } catch (e) {
      return _buildImagePlaceholder();
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.image_not_supported,
        size: 50.0,
        color: Colors.grey[600],
      ),
    );
  }
}
